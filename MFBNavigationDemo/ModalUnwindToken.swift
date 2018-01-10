import MFBNavigation

class ModalUnwindToken : MFBUnwindToken {

    private weak var modalNavigator: MFBModalNavigation?

    init(modalNavigator: MFBModalNavigation) {
        self.modalNavigator = modalNavigator
    }

    func unwind() {
        modalNavigator?.dismissModalViewController(animated: true, completion: nil)
    }
}
