//
//  ContentView.swift
//  BetterRest
//
//  Created by Dechon Ryan on 5/3/24.
//

import CoreML
import SwiftUI

struct ContentView: View {
    @State private var sleepAmount = 8.0 // possible b/c static
    @State private var wakeUp = defaultWakeTime
    @State private var coffeeAmount = 1
    
    @State private var alertTitle = ""
    @State private var suggestedBedtime = "..."
    @State private var showingAlert = false
    
    static var defaultWakeTime: Date { // static makes sense b/c default value
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("When do you want to wake up?") {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden() // voiceover will still read label
                }
                
                Section("Desired amount of sleep") {
                Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
            }
                
                Section("Daily coffee intake") {
                    Picker("How many cups?", selection: $coffeeAmount) {
                        ForEach(0...20, id: \.self) { number in
                            Text("\(number)")
                        }
                    }
                }
                
                VStack {
                    Text("Go to sleep by")
                        .multilineTextAlignment(.center)
                    Text("\(suggestedBedtime)")
                        .multilineTextAlignment(.center)
                }
                .font(.title)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("BetterRest")
            .onChange(of: sleepAmount, calclateBedtime)
            .onChange(of: wakeUp, calclateBedtime)
            .onChange(of: coffeeAmount, calclateBedtime)
            .onAppear(perform: {
                calclateBedtime()
            })
        }
        
    }
    
    func calclateBedtime() {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60 // in seconds
            let minute = (components.minute ?? 0) * 60 // in seconds
            
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            let sleepTime = wakeUp - prediction.actualSleep // a date object
            
            suggestedBedtime = sleepTime.formatted(date: .omitted, time: .shortened) // a string
        } catch {
            suggestedBedtime = "Sorry, there was an error predicting your bedtime."
        }
    }
}

#Preview {
    ContentView()
}
