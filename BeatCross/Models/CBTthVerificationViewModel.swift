//
//  Untitled.swift
//  BeatCross
//
//  Created by 神宮一敬 on 2025/02/02.
//


import Foundation
import Combine
import FirebaseCore
import FirebaseFirestore


struct CBModel: Identifiable {
    let id = UUID().uuidString
    let dataString: String
}

class CBTthVerificationViewModel: ObservableObject {
    let apiClient = APIClient.shared // これがapiClientのインスタンス
    let peripheralManager = PeripheralManager()
    let centralManager = CentralManager()
    var cancellable = [AnyCancellable]()
    @Published var RecievedData = [CBModel]()
    let auth = AuthManager.shared
    var uid: String

    
    private let db = Firestore.firestore()

    init() {
        self.uid = auth.getUserId()
        centralManager.centralPublisher.sink(receiveCompletion: { completion in
            print("complete")
        }, receiveValue: {
            self.RecievedData.append(CBModel(dataString: $0))
            }
        )
        .store(in: &cancellable)
        peripheralManager.peripheralPublisher.sink(receiveCompletion: { completion in
            print("complete")
        }, receiveValue: {
            self.RecievedData.append(CBModel(dataString: $0))
            }
        )
        .store(in: &cancellable)
        
        centralManager.encounterPublisher.sink(receiveCompletion: { completion in
            print("encounter")
        }, receiveValue: {
            print("ああああ\($0)")
            self.RecievedData.append(CBModel(dataString: $0))
            let encounterRef = self.db.collection("users").document(self.uid)

            // Atomically add a new region to the "regions" array field.
            encounterRef.updateData([
              "encounter_uid": FieldValue.arrayUnion([$0])
            ])
            }
        )
        .store(in: &cancellable)
    }


}
