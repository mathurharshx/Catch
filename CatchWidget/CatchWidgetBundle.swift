import WidgetKit
import SwiftUI

@main
struct CatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        CatchWidget()
        TaskLockScreenWidget()
        ExpenseLockScreenWidget()
        IdeaLockScreenWidget()
        NoteLockScreenWidget()
    }
}
