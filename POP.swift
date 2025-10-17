import Foundation
import _Concurrency

print("--- 🏁 Iniciando Playground 2: POP (Mídia) ---")

// MARK: - Enums e Structs

// Enum com raw value
enum MediaType: String {
    case audio
    case video
    case text
}

// Enum com associated values
enum DownloadStatus {
    case pending
    case downloading(progress: Double)
    case completed
    case failed(error: Error)
}

struct BasicInfo {
    let id: UUID
    let title: String
    let mediaType: MediaType
}

// MARK: - Protocolos (POP)

// Define o "o que" (a capacidade de ser tocado)
protocol Playable {
    var info: BasicInfo { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get set }
    
    func play()
    func stop()
}

// Define "o que" (a capacidade de ser baixado)
protocol Downloadable {
    var remoteURL: URL { get }
    
    // Função com Closure
    func download(completion: @escaping (DownloadStatus) -> Void)
}

// Composição de Protocolos
protocol MediaItem: Playable, Downloadable {
    // Pode adicionar requisitos específicos da composição
    var artist: String { get }
}

// MARK: - Implementações (Structs)

// Structs em vez de classes, focando em conformar aos protocolos
struct Song: MediaItem {
    let info: BasicInfo
    let duration: TimeInterval
    var isPlaying: Bool = false
    let remoteURL: URL
    let artist: String
    
    // Implementação de Playable
    func play() {
        print("▶️ Tocando música: \(info.title) por \(artist)")
    }
    
    func stop() {
        print("⏹️ Parando música: \(info.title)")
    }
    
    // Implementação de Downloadable
    func download(completion: @escaping (DownloadStatus) -> Void) {
        print("Iniciando download de \(info.title)...")
        // Simula o progresso
        completion(.downloading(progress: 0.5))
        // Simula a conclusão
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.completed)
        }
    }
}

struct Movie: Playable { // Este não é Downloadable
    let info: BasicInfo
    let duration: TimeInterval
    var isPlaying: Bool = false
    let director: String
    
    func play() {
        print("🎬 Tocando filme: \(info.title) (Dir: \(director))")
    }
    
    func stop() {
        print("⏹️ Parando filme: \(info.title)")
    }
}

// MARK: - Funções e Extensões (POP)

// Extensão para adicionar funcionalidade a *qualquer coisa* que seja Playable
extension Playable {
    // Implementação padrão
    func getDisplayTitle() -> String {
        return "\(info.title) (\(info.mediaType.rawValue))"
    }
}

// Função genérica que aceita *qualquer* coleção de Playable
// Não importa se é Song, Movie ou qualquer outra coisa
func startPlayback(for items: [any Playable]) {
    print("\n--- Iniciando Biblioteca ---")
    // Controle de Fluxo (forEach)
    items.forEach { $0.play() }
}

// Função que aceita Closure para filtro
func filterLibrary(items: [any Playable], by filter: (any Playable) -> Bool) -> [any Playable] {
    var filteredItems: [any Playable] = []
    
    // Controle de Fluxo (for-in e if)
    for item in items {
        if filter(item) {
            filteredItems.append(item)
        }
    }
    return filteredItems
}

// --- Execução ---

let song1 = Song(
    info: BasicInfo(id: UUID(), title: "Bohemian Rhapsody", mediaType: .audio),
    duration: 355,
    remoteURL: URL(string: "https://example.com/bohemian.mp3")!,
    artist: "Queen"
)

let movie1 = Movie(
    info: BasicInfo(id: UUID(), title: "Inception", mediaType: .video),
    duration: 9000,
    director: "Christopher Nolan"
)

let song2 = Song(
    info: BasicInfo(id: UUID(), title: "Stairway to Heaven", mediaType: .audio),
    duration: 482,
    remoteURL: URL(string: "https://example.com/stairway.mp3")!,
    artist: "Led Zeppelin"
)

// Coleção (Array) de tipos heterogêneos graças ao protocolo
let library: [any Playable] = [song1, movie1, song2]

startPlayback(for: library)

// Uso da implementação padrão (extensão)
print("\nDisplay Title da Música 1: \(song1.getDisplayTitle())")

// Uso de Função com Closure (filtro)
let onlyAudio = filterLibrary(items: library) { item in
    // Controle de Fluxo (switch)
    switch item.info.mediaType {
    case .audio:
        return true
    default:
        return false
    }
}

print("\n--- Apenas Músicas (filtrado) ---")
startPlayback(for: onlyAudio)


// MARK: - Concorrência (TaskGroup)

// Função assíncrona para baixar múltiplos itens
func downloadAll(items: [any Downloadable]) async -> [UUID: DownloadStatus] {
    print("\n--- Testando Concorrência (Download) ---")
    
    // Coleção (Dicionário)
    var statuses: [UUID: DownloadStatus] = [:]
    
    await withTaskGroup(of: (UUID, DownloadStatus).self) { group in
        for item in items {
            // Cria uma tarefa filha para cada download
            group.addTask {
                // Simula o download
                // A função `download` original usa completion,
                // então "convertemos" para async usando `withCheckedContinuation`
                let status = await withCheckedContinuation { continuation in
                    (item as! Song).download { status in // Forçando o tipo para o exemplo
                        if case .completed = status {
                            continuation.resume(returning: status)
                        }
                    }
                }
                // Retorna o ID e o status
                return ((item as! Song).info.id, status)
            }
        }
        
        // Coleta os resultados
        for await (id, status) in group {
            statuses[id] = status
            print("Download concluído para o item ID: \(id)")
        }
    }
    
    print("Todos os downloads foram concluídos")
    return statuses
}

// Execução da Concorrência
Task {
    let downloadList: [any Downloadable] = [song1, song2]
    let results = await downloadAll(items: downloadList)
    
    print("\nResultados finais do download:")
    print(results)
    
    print("\n--- 🏁 Finalizando Playground 2 ---")
}