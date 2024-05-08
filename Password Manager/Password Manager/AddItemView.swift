//
//  AddItemView.swift
//  Password Manager
//
//  Created by Vivek Nathani on 07/05/24.
//

import SwiftUI
import Security
import Foundation
import CoreData

struct AddItemView: View {
    @Binding var isPresented: Bool
    @State private var accName = ""
    @State private var accUserName = ""
    @State private var accPassword = ""
    
    @State var alertMessage = ""
    @State var isAlertPresent = false
    
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        
            VStack(spacing: 0) {
                
                Capsule().fill(.gray.opacity(0.3)).frame(width: 50, height: 5).padding(.top)
                
                Spacer()
                
                TextField("Account Name", text: $accName)
                    .padding(12)
                               .background(Color.white.opacity(0.6))
                               .cornerRadius(5)
                               .overlay(content: {
                                   RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.5))
                               })
                               .padding()
                               
                TextField("Username/ Email", text: $accUserName)
                               .padding(12)
                               .background(Color.white.opacity(0.6))
                               .cornerRadius(5)
                               .overlay(content: {
                                   RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.5))
                               })
                               .padding()
                
                SecureField("Password", text: $accPassword)
                    .padding(12)
                               .background(Color.white.opacity(0.6))
                               .cornerRadius(5)
                               .overlay(content: {
                                   RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.5))
                               })
                               .padding()
                
                
                Button(action: {
                    verifyValidations()
                }, label: {
                    Capsule().fill(.black).frame(height: 45).overlay {
                        Text("Add New Account")
                            .bold()
                            .foregroundStyle(.white)
                    }
                        
                }).padding()
                
                Spacer()
                
            }
            .frame(height: UIScreen.main.bounds.height / 2.2)
            .background(Color(red: 0.88, green: 0.88, blue: 0.88).clipShape(TopCornerRadiusShape(radius: 20)))
            .padding(.bottom, -50)
            .alert(alertMessage, isPresented: $isAlertPresent) {
                       Button("OK", role: .cancel) { }
                   }
    }
    
    func verifyValidations(){
        if accName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            alertMessage = "Account Name Should Not be Empty..!"
            isAlertPresent = true
        }else if accUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            alertMessage = "Username/ Email Should Not be Empty..!"
            isAlertPresent = true
        }else if accPassword.isEmpty{
            alertMessage = "Password Should Not be Empty..!"
            isAlertPresent = true
        }else{
                storeData()
                isPresented = false
        }
    }
    
    
    func storeData(){
        withAnimation {
            let newItem = AccDB(context: viewContext)
            newItem.accName = accName
            newItem.accUserName = accUserName
            
            guard let key = KeychainHelper.getKey() else {
                return
            }
            do {
                if let encryptedData = try encryptAES(string: accPassword, key: key) {
                    newItem.accPassword = encryptedData
                } else {
                    print("Encryption failed: No data returned")
                }
            } catch {
                print("Encryption failed: \(error)")
            }
            

            do {
                try viewContext.save()
                print("success")
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }    
}

//#Preview {
//    AddItemView()
//}

struct TopCornerRadiusShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

@objc(EncryptedItem)
public class EncryptedItem: NSManagedObject {
    @NSManaged public var encryptedData: Data?
}
