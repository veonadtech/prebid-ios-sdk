import Foundation

/// SDK-agnostic engagement events a banner source can optionally report.
/// Core wires these up generically; it never needs to know whether the
/// concrete source is GAM, Yandex, or anything else.
public protocol VeonAdSourceEngagementReporting: AnyObject {
    var onImpressionRecorded: (() -> Void)? { get set }
    var onClickRecorded: (() -> Void)? { get set }
    var onScreenWillPresent: (() -> Void)? { get set }
    var onScreenWillDismiss: (() -> Void)? { get set }
    var onScreenDidDismiss: (() -> Void)? { get set }
    var onWillLeaveApplication: (() -> Void)? { get set } // GAM never fires this — no such delegate event
}

