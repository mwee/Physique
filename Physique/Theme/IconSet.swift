import SwiftUI

// Maps prototype icon names to SF Symbols
enum AppIcon: String {
    case home = "house.fill"
    case calendar = "calendar"
    case progress = "chart.line.uptrend.xyaxis"
    case dumbbell = "dumbbell.fill"
    case timer = "timer"
    case plus = "plus"
    case check = "checkmark"
    case chevronRight = "chevron.right"
    case chevronLeft = "chevron.left"
    case chevronDown = "chevron.down"
    case ellipsis = "ellipsis"
    case flame = "flame.fill"
    case search = "magnifyingglass"
    case close = "xmark"
    case settings = "gearshape"
    case lock = "lock.fill"
    case bolt = "bolt.fill"
    case play = "play.fill"
    case edit = "pencil"
    case clock = "clock"
    case arrowUp = "arrow.up"
    case chart = "chart.bar.fill"
    case list = "list.bullet"
    case flag = "flag.fill"
    case spark = "sparkles"
    case send = "paperplane.fill"
    case clipboard = "clipboard.fill"
    case info = "info.circle"
    case link = "link"

    var image: Image {
        Image(systemName: rawValue)
    }
}
