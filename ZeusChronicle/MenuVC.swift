import UIKit
import SnapKit
import GameKit

class menuViewContoller: UIViewController, GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
    
    func auth() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = {
            (view, error) in
            if view != nil {
                self.present(view!, animated: true)
            } else {
                print(GKLocalPlayer.local.isAuthenticated)
            }
        }
    }
    
    var thunderButton: UIButton!
    var olympicButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth()
        let background = UIImageView()
        background.frame = view.frame
        view.addSubview(background)
        background.contentMode = .scaleAspectFill
        background.image = UIImage(named: "background")
        
        let logo = UIImageView()
        view.addSubview(logo)
        logo.contentMode = .scaleAspectFit
        logo.image = UIImage(named: "logo")
        logo.snp.makeConstraints({ make in
            make.centerX.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30)
            make.height.equalTo(view.snp.width).multipliedBy(0.5)
            make.width.equalTo(view.snp.width).multipliedBy(0.7)
        })
        
        let eButton = UIButton(type: .custom)
        eButton.setImage(UIImage(named: "play"), for: .normal)
        eButton.imageView?.contentMode = .scaleAspectFit
        eButton.addAction(UIAction() {
            _ in
            let vc = GameViewController()
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }, for: .touchUpInside)
        view.addSubview(eButton)
        
        eButton.snp.makeConstraints({ make in
            make.center.equalTo(view)
            make.height.equalTo(view.snp.width).multipliedBy(0.2)
            make.width.equalTo(view.snp.width).multipliedBy(0.7)
        })
        
        let mButton = UIButton(type: .custom)
        mButton.setImage(UIImage(named: "leaderboard"), for: .normal)
        mButton.imageView?.contentMode = .scaleAspectFit
        mButton.addAction(UIAction() {
            _ in
            let gcvc = GKGameCenterViewController()
            gcvc.gameCenterDelegate = self
            self.present(gcvc, animated: true)
        }, for: .touchUpInside)
        view.addSubview(mButton)
        
        mButton.snp.makeConstraints({ make in
            make.top.equalTo(eButton.snp.bottom).offset(16)
            make.centerX.equalTo(eButton)
            make.height.equalTo(view.snp.width).multipliedBy(0.2)
            make.width.equalTo(view.snp.width).multipliedBy(0.7)
        })
        
        let hButton = UIButton(type: .custom)
        hButton.setImage(UIImage(named: "olymic_game"), for: .normal)
        hButton.imageView?.contentMode = .scaleAspectFit
        hButton.addAction(UIAction() {
            _ in
            let vc = OlympicGameVC()
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }, for: .touchUpInside)
        view.addSubview(hButton)
        
        hButton.snp.makeConstraints({ make in
            make.top.equalTo(mButton.snp.bottom).offset(16)
            make.centerX.equalTo(eButton)
            make.height.equalTo(view.snp.width).multipliedBy(0.2)
            make.width.equalTo(view.snp.width).multipliedBy(0.7)
        })
        var thunder = 0
        if let thunderc = UserDefaults.standard.value(forKey: "thunder") as? Int {
            thunder = thunderc
        }
        
        var olymp = 0
        if let olympc = UserDefaults.standard.value(forKey: "olymp") as? Int {
            olymp = olympc
        }
        
        thunderButton = UIButton(type: .custom)
        thunderButton.setBackgroundImage(UIImage(named: "score"), for: .normal)
        thunderButton.setTitle("Thunder \(thunder)", for: .normal)
        thunderButton.titleLabel?.font = UIFont(name: "Victoire", size: 30)
        thunderButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(thunderButton)
        
        olympicButton = UIButton(type: .custom)
        olympicButton.setBackgroundImage(UIImage(named: "score"), for: .normal)
        olympicButton.setTitle("Olympic \(olymp)", for: .normal)
        olympicButton.titleLabel?.font = UIFont(name: "Victoire", size: 30)
        olympicButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(olympicButton)
        
        thunderButton.snp.makeConstraints({ make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(16)
            make.height.equalTo(view.safeAreaLayoutGuide.snp.width).multipliedBy(0.2)
            make.width.equalTo(view).multipliedBy(0.4)
        })
        
        olympicButton.snp.makeConstraints({ make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.width.equalTo(view).multipliedBy(0.4)
            make.height.equalTo(view.safeAreaLayoutGuide.snp.width).multipliedBy(0.2)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-16)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        var thunder = 0
        if let thunderc = UserDefaults.standard.value(forKey: "thunder") as? Int {
            thunder = thunderc
        }
        
        var olymp = 0
        if let olympc = UserDefaults.standard.value(forKey: "olymp") as? Int {
            olymp = olympc
        }
        thunderButton.setTitle("Thunder \(thunder)", for: .normal)
        olympicButton.setTitle("Olympic \(olymp)", for: .normal)
    }
    
}
