import UIKit

class OtherViewController: UIViewController {
    @IBAction func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}