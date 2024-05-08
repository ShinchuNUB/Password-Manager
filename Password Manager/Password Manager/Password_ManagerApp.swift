//
//  Password_ManagerApp.swift
//  Password Manager
//
//  Created by Vivek Nathani on 06/05/24.
//

import SwiftUI
import LocalAuthentication

@main
struct Password_ManagerApp: App {
    @State var isBiomatricAvaliable = false
    @State var successVerified = false
    let context = LAContext()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if !successVerified{
                tmpView()
                    .onAppear {
                        isBiomatricAvaliable = settingUpBiomatric()
                        beingIdentify()
                    }
            }else{
                PasswordDisplayView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(.light)
            }
        }
    }
    
    func settingUpBiomatric() -> Bool{
        var error:NSError?
        
        guard context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print(error!)
            return false
        }
        
        if context.biometryType == .faceID{
            return true
        }else if context.biometryType == .touchID{
            return true
        }else{
            print("unknown")
            return false
        }
    }
    
    func beingIdentify(){
        let reason = "Approve Face/Touch Id To Access App"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { isSuccess, Error in
            if isSuccess{
                successVerified = true
            }else{
                
                
                if let error = Error as? LAError {
                    // Check the type of error
                    if error.code.rawValue == LAError.userFallback.rawValue || error.code.rawValue == LAError.authenticationFailed.rawValue {
                        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                            DispatchQueue.main.async {
                                if success {
                                    // Authentication successful
                                    successVerified = true
                                    
                                } else {
                                    
                        
                                    // Authentication failed
                                    // Handle the failure case
                                }
                            }
                        }
                    } else {
                        
                        // Handle other types of authentication errors
                    }
                }
            }
        }
    }
    
    func tmpView() -> some View{
        ZStack{
            Color.white.ignoresSafeArea()
            
            Button {
                beingIdentify()
            } label: {
                Text("Unlock Application")
            }

        }
    }
}


