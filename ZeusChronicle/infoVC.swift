//
//  infoVC.swift
//  ZeusChronicle
//
//  Created by John on 12.03.2024.
//

import UIKit
import SpriteKit

class InfoVC: UIViewController {
    
    let string = "Welcome to \"Olympic Game,\" where you engage in a thrilling battle with Zeus using powerful artifacts! Here's the game guide:\n Step 1: Choose Your Artifact\nYou have a selection of four mighty artifacts: \n - Crown of Aida, \n - Sands of Cronus, \n - Ring of Aphrodite, \n - Chalice of Poseidon.\nDevise your strategy and select one of these artifacts by clicking on it.\nStep 2: Zeus's Artifact Selection\nZeus also chooses an artifact for the battle. His choice will remain a mystery until the fight begins.\nStep 3: Commence Battle\nOnce both you and Zeus have made your choices, click on your selected artifact to initiate the battle.\nStep 4: Battle Results\nCrown of Aida triumphs over Sands of Cronus.\nSands of Cronus conquer Chalice of Poseidon.\nRing of Aphrodite prevails over Ring of Aphrodite and Crown of Aida.\nChalice of Poseidon defeats Crown of Aida.\nAll other combinations result in a draw.\nStep 5: Victorious Outcome\nAfter each battle, the winner will be declared based on the combination of chosen artifacts.\n Congratulations if you emerge victorious! If not, don't worry – there's always a chance for a rematch.\nStep 6: Rematch and Replay\nIf you wish to face Zeus again, repeat steps 1-5 for a new game.\nGood luck in your battle against Zeus in the \"Olympic Game\" using these powerful artifacts!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let logo = UIImageView()
        self.view.addSubview(logo)
        logo.contentMode = .scaleAspectFit
        logo.image = UIImage(named: "logo_2")
        logo.snp.makeConstraints({ make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(15)
            make.height.equalTo(self.view.snp.width).multipliedBy(0.5)
            make.width.equalTo(self.view.snp.width).multipliedBy(0.7)
        })
        let textview = UITextView()
        textview.backgroundColor = .clear
        textview.text = string
        textview.textColor = .yellow
        textview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textview)
        textview.font = UIFont(name: "Victoire", size: 16)
        
        NSLayoutConstraint.activate([
            textview.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 16),
            textview.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            textview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            textview.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
        ])
        
    }
    
}
