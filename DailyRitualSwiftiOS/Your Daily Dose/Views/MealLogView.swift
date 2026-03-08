//
//  MealLogView.swift
//  Your Daily Dose
//
//  Photo-based meal logging flow: camera/photo picker → meal type → AI analysis → review → save.
//

import SwiftUI
import PhotosUI

struct MealLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: Image?
    @State private var mealType: String = "lunch"
    @State private var isAnalyzing = false
    @State private var savedMeal: Meal?
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    private let mealsService: MealsServiceProtocol = MealsService()
    private let timeContext: DesignSystem.TimeContext = .neutral
    private let dateString: String

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
    }

    private let mealTypes: [(label: String, value: String, icon: String)] = [
        ("Breakfast", "breakfast", "sun.horizon"),
        ("Lunch", "lunch", "sun.max"),
        ("Dinner", "dinner", "moon"),
        ("Snack", "snack", "carrot")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    if savedMeal != nil {
                        resultView
                    } else if isAnalyzing {
                        analyzingView
                    } else {
                        inputView
                    }
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(image: $cameraImage)
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            .onChange(of: cameraImage) { newImage in
                if let uiImage = newImage {
                    selectedImageData = uiImage.jpegData(compressionQuality: 0.8)
                    selectedImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Photo selection
            if let image = selectedImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 250)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.card)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            selectedImage = nil
                            selectedImageData = nil
                            selectedPhotoItem = nil
                            cameraImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(8)
                        }
                    }
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)

                    Text("Add a photo of your meal")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    HStack(spacing: DesignSystem.Spacing.md) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .font(DesignSystem.Typography.buttonMedium)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .font(DesignSystem.Typography.buttonMedium)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xxl)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.card)
            }

            // Meal type selector
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Meal Type")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(mealTypes, id: \.value) { type in
                        Button {
                            mealType = type.value
                            HapticManager.selectionChanged()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                Text(type.label)
                                    .font(DesignSystem.Typography.metadata)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                mealType == type.value
                                    ? timeContext.primaryColor.opacity(0.15)
                                    : DesignSystem.Colors.cardBackground
                            )
                            .foregroundColor(
                                mealType == type.value
                                    ? timeContext.primaryColor
                                    : DesignSystem.Colors.secondaryText
                            )
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .strokeBorder(
                                        mealType == type.value
                                            ? timeContext.primaryColor
                                            : DesignSystem.Colors.divider,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Analyze button
            if selectedImageData != nil {
                Button {
                    Task { await analyzeMeal() }
                } label: {
                    Label("Analyze Meal", systemImage: "sparkles")
                        .font(DesignSystem.Typography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
            }

            if let error = errorMessage {
                Text(error)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if let image = selectedImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 200)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.card)
                    .opacity(0.6)
            }

            ProgressView()
                .scaleEffect(1.5)
                .tint(timeContext.primaryColor)

            Text("Analyzing your meal...")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text("Estimating calories and macros")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if let meal = savedMeal {
                // Success header
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Meal Logged!")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                // Photo
                if let image = selectedImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 200)
                        .clipped()
                        .cornerRadius(DesignSystem.CornerRadius.card)
                }

                // Food description
                if let desc = meal.foodDescription {
                    Text(desc)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Macro breakdown
                PremiumCard(timeContext: timeContext) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Text("Nutrition Estimate")
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Spacer()
                            if let conf = meal.aiConfidence {
                                Text(String(format: "%.0f%% confidence", conf * 100))
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }

                        HStack(spacing: DesignSystem.Spacing.lg) {
                            macroItem(label: "Calories", value: "\(meal.calories)", unit: "kcal", color: .orange)
                            macroItem(label: "Protein", value: String(format: "%.0f", meal.proteinG), unit: "g", color: .red)
                            macroItem(label: "Carbs", value: String(format: "%.0f", meal.carbsG), unit: "g", color: .blue)
                            macroItem(label: "Fat", value: String(format: "%.0f", meal.fatG), unit: "g", color: .yellow)
                        }
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(DesignSystem.Typography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func macroItem(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(color)
            Text(unit)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(label)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func analyzeMeal() async {
        guard let imageData = selectedImageData else { return }
        isAnalyzing = true
        errorMessage = nil

        do {
            let meal = try await mealsService.uploadMeal(
                photoData: imageData,
                mimeType: "image/jpeg",
                mealType: mealType,
                date: dateString
            )
            await MainActor.run {
                savedMeal = meal
                isAnalyzing = false
                HapticManager.success()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to analyze meal: \(error.localizedDescription)"
                isAnalyzing = false
                HapticManager.error()
            }
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    MealLogView()
}
