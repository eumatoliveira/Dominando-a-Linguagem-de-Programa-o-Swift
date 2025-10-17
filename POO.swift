import Foundation
import _Concurrency // Necessário para Task.sleep

print("--- 🏁 Iniciando Playground 1: OOP (Banco) ---")

// MARK: - Enums e Structs

enum AccountType {
    case checking
    case savings
}

enum BankError: Error {
    case insufficientFunds
    case userNotFound
}

struct Transaction {
    let id: UUID
    let amount: Double
    let description: String
    var date: Date
}

// MARK: - Classes (OOP)

// Classe Base
class User {
    let userID: String
    var name: String
    var balance: Double
    var accountType: AccountType
    
    // Coleção (Array)
    private(set) var transactions: [Transaction] = []

    init(userID: String, name: String, initialDeposit: Double, accountType: AccountType) {
        self.userID = userID
        self.name = name
        self.balance = initialDeposit
        self.accountType = accountType
        
        if initialDeposit > 0 {
            addTransaction(amount: initialDeposit, description: "Depósito Inicial")
        }
    }
    
    // Função
    func deposit(amount: Double) {
        balance += amount
        addTransaction(amount: amount, description: "Depósito")
        print("Depósito de R$\(amount) para \(name). Novo saldo: R$\(balance)")
    }
    
    // Função com Controle de Fluxo
    func withdraw(amount: Double) throws {
        // Controle de Fluxo (guard)
        guard amount <= balance else {
            throw BankError.insufficientFunds
        }
        
        balance -= amount
        addTransaction(amount: -amount, description: "Saque")
        print("Saque de R$\(amount) de \(name). Novo saldo: R$\(balance)")
    }
    
    // Função privada auxiliar
    private func addTransaction(amount: Double, description: String) {
        let transaction = Transaction(id: UUID(), amount: amount, description: description, date: Date())
        transactions.append(transaction)
    }
    
    // Função final (não pode ser sobrescrita)
    final func getAccountSummary() -> String {
        return "Resumo: \(name) (\(accountType)) - Saldo: R$\(balance)"
    }
}

// Subclasse (Herança)
class PremiumUser: User {
    var cashbackRate: Double
    
    init(userID: String, name: String, initialDeposit: Double, cashbackRate: Double = 0.01) {
        self.cashbackRate = cashbackRate
        // Chama o init da superclasse
        super.init(userID: userID, name: name, initialDeposit: initialDeposit, accountType: .checking)
    }
    
    // Sobrescrita de Função (Polimorfismo)
    override func deposit(amount: Double) {
        let cashback = amount * cashbackRate
        let totalDeposit = amount + cashback
        
        balance += totalDeposit
        addTransaction(amount: totalDeposit, description: "Depósito com Cashback")
        print("Depósito de R$\(amount) para \(name) (Premium). Cashback de R$\(cashback) aplicado. Novo saldo: R$\(balance)")
    }
}

// Classe principal que gerencia outras classes
class Bank {
    // Coleção (Dicionário)
    var users: [String: User] = [:]
    
    func registerUser(user: User) {
        users[user.userID] = user
        print("Usuário \(user.name) registrado no banco")
    }
    
    // Função com Closure como parâmetro
    func applyInterest(to accountType: AccountType, rate: Double, completion: (Int, Double) -> Void) {
        var usersAffected = 0
        var totalInterestApplied: Double = 0
        
        // Controle de Fluxo (for-in)
        for user in users.values {
            // Controle de Fluxo (if)
            if user.accountType == accountType {
                let interest = user.balance * rate
                user.balance += interest
                usersAffected += 1
                totalInterestApplied += interest
            }
        }
        
        // Chamando a closure
        completion(usersAffected, totalInterestApplied)
    }
    
    // MARK: - Concorrência (async/await)
    
    // Simula a busca de um histórico de transações em um servidor externo
    func fetchTransactionHistory(userID: String) async throws -> [Transaction] {
        print("\nBuscando histórico para \(userID)... (Simulando 2s de espera)")
        
        // Simula uma tarefa assíncrona (ex: chamada de rede)
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        // Controle de Fluxo (if let)
        if let user = users[userID] {
            return user.transactions
        } else {
            throw BankError.userNotFound
        }
    }
}

// --- Execução ---

let banco = Bank()
let user1 = User(userID: "u1", name: "Ana", initialDeposit: 500, accountType: .savings)
let user2 = PremiumUser(userID: "u2", name: "Bruno", initialDeposit: 2000)

banco.registerUser(user: user1)
banco.registerUser(user: user2)

print("")
user1.deposit(amount: 100)
user2.deposit(amount: 100) // Receberá cashback

do {
    try user1.withdraw(amount: 50)
    try user2.withdraw(amount: 3000) // Isso deve falhar
} catch BankError.insufficientFunds {
    print("Erro: Saldo insuficiente")
} catch {
    print("Erro inesperado: \(error)")
}

print("")
print(user1.getAccountSummary())
print(user2.getAccountSummary())

// Uso de Função com Closure
banco.applyInterest(to: .savings, rate: 0.05) { (count, total) in
    print("\nJuros aplicado a \(count) contas de poupança. Total de juros: R$\(total)")
}

print(user1.getAccountSummary()) // Saldo da Ana deve ter aumentado

// Execução da Concorrência
print("\n--- Testando Concorrência ---")

Task {
    do {
        let history = try await banco.fetchTransactionHistory(userID: "u1")
        print("\nHistórico de 'Ana' recebido:")
        // Controle de Fluxo (forEach)
        history.forEach { print("  - \($0.description): R$\($0.amount)") }
    } catch {
        print("Erro ao buscar histórico: \(error)")
    }
    
    print("\n--- 🏁 Finalizando Playground 1 ---")
}