import MFBNavigation
import UIKit

private var UnwindTokenKey: UInt8 = 0

class DemoViewController: UITableViewController {

    var pushPopNavigator: MFBPushPopNavigation!
    var modalNavigator: MFBModalNavigation!

    private var animateTransitions = true

    override func viewDidLoad() {
        precondition(pushPopNavigator != nil)
        precondition(modalNavigator != nil)

        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        precondition(indexPath.section == 0)

        let nextViewController = (self.storyboard?.instantiateViewController(withIdentifier: "Red"))!

        switch (indexPath.row) {
        case 0:
            let unwindToken = pushPopNavigator.currentUnwindToken()
            objc_setAssociatedObject(nextViewController, &UnwindTokenKey, unwindToken, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            nextViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unwind", style: .plain, target: unwindToken, action: #selector(MFBUnwindToken.unwind))
            pushPopNavigator.push(nextViewController, animated: animateTransitions, completion: nil)
        case 1:
            let unwindToken = ModalUnwindToken(modalNavigator: modalNavigator)
            objc_setAssociatedObject(nextViewController, &UnwindTokenKey, unwindToken, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            nextViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unwind", style: .plain, target: unwindToken, action: #selector(MFBUnwindToken.unwind))
            let navigationController = UINavigationController(rootViewController: nextViewController)
            modalNavigator.showModalViewController(navigationController, animated: animateTransitions, completion: nil)
        case 2:
            let alert = UIAlertController(title: "Title", message: "Hello World!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
        default:
            fatalError("should not happen")
        }
    }

    @IBAction func didChangeAnimateTransitions(_ sender: UISwitch) {
        animateTransitions = sender.isOn
    }

}
