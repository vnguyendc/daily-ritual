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
    @State private var mealType: String
    @State private var isAnalyzing = false
    @State private var savedMeal: Meal?
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var hasAutoOpenedCamera = false

    // Result animation state
    @State private var displayedCalories: Int = 0
    @State private var displayedProtein: Double = 0
    @State private var displayedCarbs: Double = 0
    @State private var displayedFat: Double = 0
    @State private var showEditValues = false
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    @State private var isSavingEdits = false

    private let mealsService: MealsServiceProtocol = MealsService()
    private let timeContext: DesignSystem.TimeContext = .neutral
    private let dateString: String

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        // Auto-detect meal type from time of day
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 11 {
            _mealType = State(initialValue: "breakfast")
        } else if hour < 15 {
            _mealType = State(initialValue: "lunch")
        } else if hour < 21 {
            _mealType = State(initialValue: "dinner")
        } else {
            _mealType = State(initialValue: "snack")
        }
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
            .onAppear {
                if !hasAutoOpenedCamera {
                    hasAutoOpenedCamera = true
                    showCamera = true
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                        }
                        // Auto-analyze after photo library selection
                        await analyzeMeal()
                    }
                }
            }
            .onChange(of: cameraImage) { newImage in
                if let uiImage = newImage {
                    selectedImageData = uiImage.jpegData(compressionQuality: 0.8)
                    selectedImage = Image(uiImage: uiImage)
                    // Auto-analyze after camera capture
                    Task { await analyzeMeal() }
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
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .font(DesignSystem.Typography.buttonMedium)
                        }
                        .buttonStyle(.borderedProminent)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
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

                // Photo with confidence ring
                if let image = selectedImage {
                    ZStack {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 200)
                            .clipped()
                            .cornerRadius(DesignSystem.CornerRadius.card)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .strokeBorder(confidenceColor(for: meal.aiConfidence), lineWidth: 3)
                    }
                }

                // Food tags
                if let desc = meal.foodDescription {
                    let tags = desc.components(separatedBy: CharacterSet(charactersIn: ",\n"))
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(timeContext.primaryColor)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(timeContext.primaryColor.opacity(0.1))
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(timeContext.primaryColor.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // Macro breakdown with counting animation
                PremiumCard(timeContext: timeContext) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Text("Nutrition Estimate")
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Spacer()
                            if let conf = meal.aiConfidence {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(confidenceColor(for: meal.aiConfidence))
                                        .frame(width: 8, height: 8)
                                    Text(String(format: "%.0f%% confidence", conf * 100))
                                        .font(DesignSystem.Typography.metadata)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                            }
                        }

                        HStack(spacing: DesignSystem.Spacing.lg) {
                            macroItem(label: "Calories", value: "\(displayedCalories)", unit: "kcal", color: .orange)
                            macroItem(label: "Protein", value: String(format: "%.0f", displayedProtein), unit: "g", color: .red)
                            macroItem(label: "Carbs", value: String(format: "%.0f", displayedCarbs), unit: "g", color: .blue)
                            macroItem(label: "Fat", value: String(format: "%.0f", displayedFat), unit: "g", color: .yellow)
                        }
                    }
                }
                .onAppear {
                    animateMacros(for: meal)
                }

                // Edit values expandable section
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEditValues.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("Edit values")
                                .font(DesignSystem.Typography.buttonSmall)
                            Spacer()
                            Image(systemName: showEditValues ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                    }
                    .buttonStyle(.plain)

                    if showEditValues {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            editField(label: "Calories (kcal)", text: $editCalories)
                            editField(label: "Protein (g)", text: $editProtein)
                            editField(label: "Carbs (g)", text: $editCarbs)
                            editField(label: "Fat (g)", text: $editFat)

                            Button {
                                Task { await saveEdits(for: meal) }
                            } label: {
                                Group {
                                    if isSavingEdits {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Save")
                                            .font(DesignSystem.Typography.buttonMedium)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingEdits)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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

    private func confidenceColor(for confidence: Double?) -> Color {
        guard let conf = confidence else { return .yellow }
        if conf >= 0.75 { return .green }
        if conf >= 0.50 { return .yellow }
        return .orange
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 130, alignment: .leading)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.CornerRadius.button)
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
                // Seed edit fields with AI values
                editCalories = "\(meal.calories)"
                editProtein = String(format: "%.0f", meal.proteinG)
                editCarbs = String(format: "%.0f", meal.carbsG)
                editFat = String(format: "%.0f", meal.fatG)
                savedMeal = meal
                isAnalyzing = false
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to analyze meal: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }

    private func animateMacros(for meal: Meal) {
        let steps = 20
        let duration = 0.8
        let interval = duration / Double(steps)
        let targetCalories = meal.calories
        let targetProtein = meal.proteinG
        let targetCarbs = meal.carbsG
        let targetFat = meal.fatG

        for i in 1...steps {
            let progress = Double(i) / Double(steps)
            let delay = interval * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedCalories = Int(Double(targetCalories) * progress)
                displayedProtein = targetProtein * progress
                displayedCarbs = targetCarbs * progress
                displayedFat = targetFat * progress
            }
        }
    }

    private func saveEdits(for meal: Meal) async {
        isSavingEdits = true
        var updates: [String: Any] = [:]
        if let cal = Int(editCalories) { updates["user_calories"] = cal }
        if let p = Double(editProtein) { updates["user_protein_g"] = p }
        if let c = Double(editCarbs) { updates["user_carbs_g"] = c }
        if let f = Double(editFat) { updates["user_fat_g"] = f }
        guard !updates.isEmpty else { isSavingEdits = false; return }

        do {
            let updated = try await mealsService.updateMeal(id: meal.id, updates: updates)
            await MainActor.run {
                savedMeal = updated
                displayedCalories = updated.calories
                displayedProtein = updated.proteinG
                displayedCarbs = updated.carbsG
                displayedFat = updated.fatG
                showEditValues = false
                isSavingEdits = false
            }
        } catch {
            await MainActor.run {
                isSavingEdits = false
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
