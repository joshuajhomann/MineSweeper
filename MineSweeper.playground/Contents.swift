import UIKit
import GameKit
import PlaygroundSupport

struct Board {
  enum Square: Equatable, CustomStringConvertible {
    case bomb, empty(Int)
    var description: String {
      switch self {
      case .bomb: return "💣"
      case .empty(let count): return count == 0 ? " " : count.description
      }
    }
  }
  enum GameState {
    case playing, won, lost
  }
  var gameState: GameState {
    var won = true
    for index in (0..<dimension*dimension) {
      if squares[index] == .bomb && visibility[index] == true {
        return .lost
      }
      if case .empty = squares[index],
        visibility[index] == false {
        won = false
      }
    }
    return won ? .won : .playing
  }
  let dimension: Int
  private var squares: [Square] = []
  private var visibility: [Bool] = []
  private let adjacentOffsets: [(Int, Int)] = (-1...1).flatMap {x in (-1...1).map { y in (x,y)}}
    .filter {(x,y) in !(x == 0 && y == 0)}
  init(dimension: Int, bombCount: Int) {
    self.dimension = dimension
    let shuffled = (0..<(dimension * dimension)).map { $0 < bombCount ? Square.bomb : Square.empty(0)}.shuffled
    squares = shuffled.enumerated().map { index, element in
      if element == .bomb {
        return .bomb
      }
      let count = adjacentOffsets.map {(x,y) in (x + index % dimension, y + index / dimension)}
        .reduce(0) { result, coordinate in
          let (x, y) = coordinate
          guard x >= 0 && y >= 0 && x < dimension && y < dimension else {
            return result
          }
          return result + (shuffled[x + y * dimension] == .bomb ? 1 : 0)
      }
      return .empty(count)
    }
    visibility = [Bool](repeating: false, count: dimension*dimension)
  }
  mutating func reveal(x: Int, y: Int) {
    guard x >= 0 && y >= 0 && x < dimension && y < dimension else {
      return
    }
    let index = x+y*dimension
    guard visibility[index] == false else {
      return
    }
    visibility[index] = true
    guard case let .empty(count) = squares[index], count == 0 else {
        return
    }
    adjacentOffsets.map {i,j in (i+x, j+y)}.forEach {(x, y) in self.reveal(x: x, y: y)}
  }
  func descriptionFor(x: Int, y: Int) -> String {
    let index = x+y*dimension
    return visibility[index] ? squares[index].description : "?"
  }
}

extension Array {
  var shuffled: [Element] {
    return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: self) as! [Element]
  }
}

class ViewController: UIViewController {
  private let dimension = 8
  private let bombCount = 8
  private let labelAttributes: [NSAttributedStringKey: Any] = [.font:  UIFont.systemFont(ofSize: 32)]
  private lazy var board = {
    Board(dimension: self.dimension, bombCount: self.bombCount)
  }()
  private var labels: [[UILabel]] = []
  private var labelDimension: CGFloat = 0
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let minimumViewDimension = min(view.bounds.size.height, view.bounds.size.width)
    labelDimension = minimumViewDimension / CGFloat(dimension)
    labels = (0 ..< dimension).map { _ in
      (0 ..< dimension).map { _ -> (UILabel) in
        let label = UILabel()
        label.textAlignment = .center
        self.view.addSubview(label)
        return label
      }
    }
    updateLabels()
    view.layoutIfNeeded()
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard !labels.isEmpty else {
      return
    }
    let minimumViewDimension = min(view.bounds.size.height, view.bounds.size.width)
    labelDimension = minimumViewDimension / CGFloat(dimension)
    (0 ..< dimension).forEach { y in
      (0 ..< dimension).forEach { x in
        self.labels[x][y].frame = CGRect(x: CGFloat(x) * labelDimension, y: CGFloat(y) * labelDimension, width: labelDimension, height: labelDimension)
      }
    }
  }
  
  func updateLabels() {
    (0 ..< dimension).forEach { y in
      (0 ..< dimension).forEach { x in
        labels[x][y].attributedText = NSAttributedString(string: board.descriptionFor(x: x, y: y), attributes: self.labelAttributes)
      }
    }
  }

  @objc private func tap(recognizer: UITapGestureRecognizer) {
    guard board.gameState == .playing else {
      return
    }
    let point = recognizer.location(in: view)
    board.reveal(x: Int(point.x / labelDimension), y: Int(point.y / labelDimension))
    updateLabels()
    if board.gameState == .won {
      view.backgroundColor = .green
    }
    if board.gameState == .lost {
      view.backgroundColor = .red
    }
  }
}

let v = ViewController()
v.view.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
PlaygroundPage.current.liveView = v.view
