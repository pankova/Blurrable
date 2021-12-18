//
//  ViewController.swift
//  Blurrable
//
//  Created by Mariya Pankova on 10.12.2021.
//

import PhotosUI
import UIKit

class ViewController: UIViewController {

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView! {
        didSet {
            livePhotoView.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var alphaValueLabel: UILabel!
    @IBOutlet var blurPicker: UIPickerView!
    @IBOutlet var alphaSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        visualEffectView.effect = nil
        setupBlurPicker()
        setupSlider()
        setupGR()
    }

    func setupBlurPicker() {
        blurPicker.dataSource = self
        blurPicker.delegate = self
    }

    func setupSlider() {
        alphaSlider.minimumValue = 0
        alphaSlider.maximumValue = 1
        alphaSlider.value = 1
        alphaSlider.isContinuous = true
    }

    func setupGR() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(showFullscreenImage))
        backgroundView.addGestureRecognizer(tapGR)
    }

    @objc func showFullscreenImage() {
        guard let preview = backgroundView.snapshotView(afterScreenUpdates: false),
              preview.frame.height > 0 else { return }

        let imageVC = UIViewController()
        imageVC.view.backgroundColor = .systemBackground
        imageVC.view.addSubview(preview)
        preview.translatesAutoresizingMaskIntoConstraints = false

        let previewReferencsSize = imageView.image?.size
            ?? livePhotoView.livePhoto?.size
            ?? UIScreen.main.bounds.size
        let previewWidth = max(previewReferencsSize.width, previewReferencsSize.height)
            / previewReferencsSize.width
            * UIScreen.main.bounds.width
        let previewRatio = backgroundView.frame.width / backgroundView.frame.height

        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: imageVC.view.centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: imageVC.view.centerYAnchor),
            preview.widthAnchor.constraint(equalTo: preview.heightAnchor, multiplier: previewRatio),
            preview.widthAnchor.constraint(equalToConstant: previewWidth),
        ])
        present(imageVC, animated: true, completion: nil)
    }
}

extension ViewController {
    @IBAction func alphaChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        visualEffectView.alpha = CGFloat(slider.value)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let number = NSNumber(value: slider.value)
        let formattedValue = formatter.string(from: number)!
        alphaValueLabel.text = formattedValue
    }

    @IBAction func selectImage(_ sender: Any) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @IBAction func clearImage(_ sender: Any) {
        imageView.image = nil
        livePhotoView.livePhoto = nil
    }

    @IBAction func selectColor(_ sender: Any) {
        let picker = UIColorPickerViewController()
        picker.selectedColor = self.view.backgroundColor!
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @IBAction func clearColor(_ sender: Any) {
        backgroundView.backgroundColor = .clear
    }
}

extension ViewController: UIPickerViewDataSource {
    var blurStyles: [UIBlurEffect.Style?] {
        [
            nil,
            .extraLight,
            .light,
            .dark,
            .regular,
            .prominent,
            .systemUltraThinMaterial,
            .systemThinMaterial,
            .systemMaterial,
            .systemThickMaterial,
            .systemChromeMaterial,
            .systemUltraThinMaterialLight,
            .systemThinMaterialLight,
            .systemMaterialLight,
            .systemThickMaterialLight,
            .systemChromeMaterialLight,
            .systemUltraThinMaterialDark,
            .systemThinMaterialDark,
            .systemMaterialDark,
            .systemThickMaterialDark,
            .systemChromeMaterialDark,
        ]
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        blurStyles.count
    }
}

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
       blurStyles[row]?.title ?? "no blur"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let style = blurStyles[row] else  {
            visualEffectView.effect = nil
            return
        }
        let blurEffect = UIBlurEffect(style: style)
        visualEffectView.effect = blurEffect
    }
}

extension ViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        backgroundView.backgroundColor = viewController.selectedColor
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)

        guard let result = results.first,
              let assetIdentifier = result.assetIdentifier else { return }
        let itemProvider = result.itemProvider

        let loadCompletion: (NSItemProviderReading?, Error?) -> Void = { [weak self] livePhoto, error in
            DispatchQueue.main.async {
                self?.imagePickerCompletion(assetIdentifier: assetIdentifier, object: livePhoto, error: error)
            }
        }

        if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            itemProvider.loadObject(ofClass: PHLivePhoto.self, completionHandler: loadCompletion)
        } else if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self, completionHandler: loadCompletion)
        } else {
            displayImageError(for: BlurError.unsupportedType)
        }
    }
}

extension ViewController {
    func imagePickerCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        if let livePhoto = object as? PHLivePhoto {
            displayLivePhoto(livePhoto)
        } else if let image = object as? UIImage {
            print(image.size)

            displayImage(image)
        } else if let error = error {
            displayImageError(for: error)
        }
    }

    func displayLivePhoto(_ livePhoto: PHLivePhoto?) {
        imageView.isHidden = true
        livePhotoView.isHidden = false
        livePhotoView.livePhoto = livePhoto
    }

    func displayImage(_ image: UIImage?) {
        livePhotoView.isHidden = true
        imageView.isHidden = false
        imageView.image = image
    }

    func displayImageError(for error: Error?) {
        let title: String = {
            if let blurErrror = error as? BlurError {
                return blurErrror.description
            } else {
                return error?.localizedDescription ?? "Unknown error"
            }
        }()
        let alert = UIAlertController(
            title: title,
            message: "Please, write to developer",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
}
