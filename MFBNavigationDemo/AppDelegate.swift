import MFBNavigation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let demoViewController = UIStoryboard(name: "Demo", bundle: nil).instantiateInitialViewController() as! DemoViewController
        let navigationController = UINavigationController(rootViewController: demoViewController)

        let transitionQueue = MFBSuspendibleUIQueue()
        demoViewController.pushPopNavigator = MFBPushPopNavigator(navigationController: navigationController, transitionQueue: transitionQueue, modalNavigator: nil)
        demoViewController.modalNavigator = MFBModalNavigator(transitionQueue: transitionQueue, viewController: demoViewController)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

}

