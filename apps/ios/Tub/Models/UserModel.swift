//
//  PlayerModel.swift
//  Tub
//
//  Created by Henry on 10/3/24.
//

import SwiftUI
import Combine
import TubAPI
import ApolloCombine

class UserModel: ObservableObject {
    @Published var balance: Double = 0
    private var cancellables: Set<AnyCancellable> = []
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        startBalancePolling()
    }
    
    private func startBalancePolling() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchBalance()
            }
            .store(in: &cancellables)
    }
    
    private func fetchBalance() {
        let creditQuery = GetAccountBalanceCreditQuery(accountId: Uuid(userId))
        let debitQuery = GetAccountBalanceDebitQuery(accountId: Uuid(userId))
        
        let creditPublisher = Network.shared.apollo.watchPublisher(query: creditQuery)
        let debitPublisher = Network.shared.apollo.watchPublisher(query: debitQuery)
        
        Publishers.CombineLatest(creditPublisher, debitPublisher)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error fetching balance: \(error)")
                }
            } receiveValue: { [weak self] creditResult, debitResult in
                switch (creditResult, debitResult) {
                case (.success(let creditData), .success(let debitData)):
                    let creditAmount = creditData.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let debitAmount = debitData.data?.account_transaction_aggregate.aggregate?.sum?.amount ?? 0
                    let balance = Double(creditAmount - debitAmount) / 1e9
                    DispatchQueue.main.async {
                        // print("balance", balance)
                        self?.balance = balance
                    }
                case (.failure(let error), _), (_, .failure(let error)):
                    print("Error fetching balance: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
