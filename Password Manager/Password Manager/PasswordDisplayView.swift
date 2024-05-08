//
//  PasswordDisplayView.swift
//  Password Manager
//
//  Created by Vivek Nathani on 06/05/24.
//

import SwiftUI
import CryptoKit


struct PasswordDisplayView: View {
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AccDB.accName, ascending: true)],
        animation: .default)
    var items: FetchedResults<AccDB>
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var addNewValue = false
    @State var editNewValue = false
    @State var indxOfData = -1
    
    var body: some View {
        ZStack(alignment: .bottom){
            Color.gray.opacity(0.2).ignoresSafeArea(.all)
            ScrollView{
                VStack(spacing: 5){
                    VStack(){
                        Text("Password Manager")
                            .bold()
                        
                    }.frame(maxWidth: .infinity, alignment: .leading).padding()
                    
                    Divider()
                    
                    ForEach(0..<items.count, id:\.self){ item in
                        CardView(name: items[item].accName ?? "", password: items[item].accPassword).onTapGesture {
                            indxOfData = item
                            editNewValue = true
                        }
                    }
                }
            }
    
            VStack{
                Spacer()
                
                RoundedRectangle(cornerRadius: 10).fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "plus")
                            .resizable()
                            .foregroundStyle(Color.white)
                            .frame(width: 25, height: 25)
                    }
            }.frame(maxWidth: .infinity, alignment: .trailing).padding([.bottom,.trailing], 30).onTapGesture {
                addNewValue = true
            }
            
            if addNewValue{
                ZStack(alignment: .bottom){
                    
                    Color.black.opacity(0.5).ignoresSafeArea().onTapGesture {
                        addNewValue = false
                    }
                    
                    
                    AddItemView(isPresented: $addNewValue)
                        .offset(y: addNewValue ? 0 : UIScreen.main.bounds.height)
                        .animation(.easeInOut, value: addNewValue)
                    
                }
            }
            
            if editNewValue{
                ZStack(alignment: .bottom){
                    
                        Color.black.opacity(0.5).ignoresSafeArea().onTapGesture {
                            editNewValue = false
                        }
                    
                    
                    EditItemView(isPresented: $editNewValue, itemIndex: $indxOfData)
                        .offset(y: editNewValue ? 0 : UIScreen.main.bounds.height)
                        .animation(.easeInOut, value: editNewValue)
                }
            }
            
        }.onAppear {
            let key: SymmetricKey

            // Retrieve the key from the keychain or generate a new one if it doesn't exist
            if let savedKey = KeychainHelper.getKey() {
                key = savedKey
                print("Using existing key from keychain")
            } else {
                key = SymmetricKey(size: .bits256)
                KeychainHelper.saveKey(key)
                print("Generated and saved new key to keychain")
            }
            
        }
    }
    
    
}

struct CardView: View {
    var name: String
    var password: Data?
    
    var body: some View {
        
        Capsule().fill(.white).frame(height: 65).overlay(content: {
            HStack{
                Text(name)
                    .bold()
                    .padding(.leading, 25)
                
                Text(decryptPassToStar())
                    .opacity(0.5)
                    .padding([.top,.leading], 5)
                    
                Spacer()
                
                Image(systemName: "chevron.right")
                    .padding(.trailing, 25)
            }
        }).padding([.leading,.trailing]).padding(.top, 15)
           
    }
    
    func decryptPassToStar() -> String {
        do{
            if let key = KeychainHelper.getKey() {
                let decryptedString = try decryptAES(data: password ?? Data(), key: key)
                return starsForStringCount(decryptedString)
                
            }
            
        }
        catch {
            print(error)
        }
        return ""
    }
    
    
}


extension View{
    func starsForStringCount(_ input: String) -> String {
        let starString = String(repeating: "*", count: input.count)
        return starString
    }
    
    func encryptAES(string: String, key: SymmetricKey) throws -> Data? {
        let data = Data(string.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined
    }

    func decryptAES(data: Data, key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return decryptedString
    }
}

enum EncryptionError: Error {
    case decryptionFailed
}


struct KeychainHelper {
    static let keychainService = "com.vivek.Password-Manager.keychain"
    static let keychainKey = "encryptionKey"

    enum KeychainError: Error {
            case unableToSaveKey(OSStatus)
            case decryptionFailed
        }

        static func saveKey(_ key: SymmetricKey) {
            do {
                let keyData = Data(key.withUnsafeBytes { Array($0) })
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: keychainService,
                    kSecAttrAccount as String: keychainKey,
                    kSecValueData as String: keyData
                ]

                let status = SecItemAdd(query as CFDictionary, nil)
                guard status == errSecSuccess else {
                    throw KeychainError.unableToSaveKey(status)
                }
            } catch {
                print("Error saving key to keychain: \(error)")
            }
        }

        static func getKey() -> SymmetricKey? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainKey,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            guard status == errSecSuccess,
                  let keyData = item as? Data else {
                print("Error retrieving key from keychain")
                return nil
            }

            
            return SymmetricKey(data: keyData)
            
        }
}
