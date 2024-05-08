//
//  EditItemView.swift
//  Password Manager
//
//  Created by Vivek Nathani on 08/05/24.
//

import SwiftUI
import CoreData

struct EditItemView: View {
    @Binding var isPresented: Bool
    @Binding var itemIndex: Int
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AccDB.accName, ascending: true)],
        animation: .default)
    var items: FetchedResults<AccDB>
    @State var accName: String = ""
    @State var accUserName: String = ""
    @State var accPassword: String = ""
    @State var isEdit = false
    @State var isPasswordVisible = false
    @State var alertMessage = ""
    @State var isAlertPresent = false
    
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        
            VStack(spacing: 0) {
                
                Capsule().fill(.gray.opacity(0.3)).frame(width: 50, height: 5).padding(.top)
                
                Spacer()
                
                if isEdit {
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
                        isEdit = false
                    }, label: {
                        Capsule().fill(.black).frame(height: 45).overlay {
                            Text("Update Data")
                                .bold()
                                .foregroundStyle(.white)
                        }
                            
                    }).padding()
                    
                    
                }else{
                    
                
                    VStack(alignment: .leading, spacing: 20){
                        Text("Account Details")
                            .bold()
                            .foregroundStyle(.blue)
                            .padding()
                        
                        VStack(alignment: .leading){
                            Text("Account Type")
                                .font(.custom("", size: 12))
                                .foregroundStyle(.gray.opacity(0.4))
                                
                            
                            Text(accName)
                                .bold()
                                .padding([.top,.leading], 2)
                                
                            
                        }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing])
                        
                        VStack(alignment: .leading){
                            Text("Username/ Email")
                                .font(.custom("", size: 12))
                                .foregroundStyle(.gray.opacity(0.4))
                                
                            
                            Text(accUserName)
                                .bold()
                                .padding([.top,.leading], 2)
                                
                            
                        }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing])
                        
                        VStack(alignment: .leading){
                        
                            Text("Password")
                                .font(.custom("", size: 12))
                                .foregroundStyle(.gray.opacity(0.4))
                                
                            HStack{
                                Text(isPasswordVisible ? accPassword : starsForStringCount(accPassword))
                                    .bold()
                                    .padding([.top,.leading], 2)
                                
                                Spacer()
                                
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundStyle(.gray.opacity(0.4))
                                    .onTapGesture {
                                    isPasswordVisible.toggle()
                                }
                            }
                            
                        }.frame(maxWidth: .infinity, alignment: .leading).padding([.leading, .trailing])
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack{
                        Button(action: {
                            isEdit = true
                        }, label: {
                            Capsule().fill(.black).frame(height: 45).overlay {
                                Text("Edit")
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                                
                        }).padding()
                        
                        
                        Button(action: {
                            deleteItems()
                            isPresented = false
                        }, label: {
                            Capsule().fill(.red).frame(height: 45).overlay {
                                Text("Delete")
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                                
                        }).padding()
                    }.padding([.top,.bottom], 30)
                    
                }
                Spacer()
                
            }
            .frame(height: UIScreen.main.bounds.height / 2.2)
            .background(Color(red: 0.88, green: 0.88, blue: 0.88).clipShape(TopCornerRadiusShape(radius: 20)))
            .padding(.bottom, -50)
            .alert(alertMessage, isPresented: $isAlertPresent) {
                       Button("OK", role: .cancel) { }
                   }
            .onAppear{
                if itemIndex > -1  {
                    accName = items[itemIndex].accName ?? ""
                    accUserName = items[itemIndex].accUserName ?? ""
                    
                    do{
                        if let key = KeychainHelper.getKey() {
                            let decryptedString = try decryptAES(data: items[itemIndex].accPassword ?? Data(), key: key)
                            accPassword = decryptedString
                        }
                        
                    }
                    catch {
                        print(error)
                    }
                    
                }
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
                editData()
                isPresented = false
        }
    }
    
    func deleteItems() {
        
        let fetchRequest: NSFetchRequest<AccDB> = AccDB.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "accName == %@", accName)
            
            do {
                let itemsToDelete = try viewContext.fetch(fetchRequest)
                
                // Delete each item
                for item in itemsToDelete {
                    viewContext.delete(item)
                }
                
                // Save the changes
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error deleting items: \(error)")
            }
        
    }
    
    
    func editData(){
        withAnimation {
            
            let compoundPredicate = NSPredicate(format: "accName == %@ AND accUserName == %@", items[itemIndex].accName ?? "", items[itemIndex].accUserName ?? "")
                
                // Fetch items with the compound predicate
                let fetchRequest: NSFetchRequest<AccDB> = AccDB.fetchRequest()
                fetchRequest.predicate = compoundPredicate
                
                do {
                    let items = try viewContext.fetch(fetchRequest)
                    
                    // Ensure only one item is found
                    guard let itemToEdit = items.first else {
                        print("Item with specified conditions not found")
                        return
                    }
                    
                    // Modify the accName property of the found item
                    itemToEdit.accName = accName
                    itemToEdit.accUserName = accUserName
                    
                    guard let key = KeychainHelper.getKey() else {
                        return
                    }
                    do {
                        if let encryptedData = try encryptAES(string: accPassword, key: key) {
                            itemToEdit.accPassword = encryptedData
                        } else {
                            print("Encryption failed: No data returned")
                        }
                    } catch {
                        print("Encryption failed: \(error)")
                    }
                    
                    
                    // Save the changes
                    try viewContext.save()
                } catch {
                    // Handle the error appropriately
                    print("Error editing item: \(error)")
                }
            
        }
    }
}
