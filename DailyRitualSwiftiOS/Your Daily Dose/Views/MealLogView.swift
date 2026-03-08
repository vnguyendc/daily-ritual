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
    @State private var hasShownInitialCamera = false

    // Counting animation state
    @State private var displayCalories: Int = 0
    @State private var displayProtein: Double = 0
    @State private var displayCarbs: Double = 0
    @State private var displayFat: Double = 0

    // Edit values state
    @State private var isEditExpanded = false
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
        // Auto-detect meal type based on time of day
        _mealType = State(initialValue: MealLogView.autoDetectMealType())
    }

    private static func autoDetectMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<11: return "breakfast"
        case 11..<15: return "lunch"
        case 15..<21: return "dinner"
        default: return "snack"
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
                if !hasShownInitialCamera {
                    hasShownInitialCamera = true
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
                        await analyzeMeal()
                    }
                }
            }
            .onChange(of: cameraImage) { newImage in
                if let uiImage = newImage {
                    selectedImageData = uiImage.jpegData(compressionQuality: 0.8)
                    selectedImage = Image(uiImage: uiImage)
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

                        if let confidence = meal.aiConfidence {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .strokeBorder(confidenceColor(confidence), lineWidth: 3)
                                .frame(maxHeight: 200)
                        }
                    }
                    .frame(maxHeight: 200)
                }

                // Food item tags
                if let desc = meal.foodDescription, !desc.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(foodItems(from: desc), id: \.self) { item in
                                Text(item)
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(timeContext.primaryColor.opacity(0.12))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                                        .fill(confidenceColor(conf))
                                        .frame(width: 6, height: 6)
                                    Text(String(format: "%.0f%% confidence", conf * 100))
                                        .font(DesignSystem.Typography.metadata)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                            }
                        }

                        HStack(spacing: DesignSystem.Spacing.lg) {
                            macroItem(label: "Calories", value: "\(displayCalories)", unit: "kcal", color: .orange)
                            macroItem(label: "Protein", value: String(format: "%.0f", displayProtein), unit: "g", color: .red)
                            macroItem(label: "Carbs", value: String(format: "%.0f", displayCarbs), unit: "g", color: .blue)
                            macroItem(label: "Fat", value: String(format: "%.0f", displayFat), unit: "g", color: .yellow)
                        }
                        .onAppear {
                            startCountingAnimation(
                                calories: meal.calories,
                                protein: meal.proteinG,
                                carbs: meal.carbsG,
                                fat: meal.fatG
                            )
                        }
                    }
                }

                // Edit values section (collapsed by default)
                editValuesSection(meal: meal)

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

    // MARK: - Edit Values Section

    private func editValuesSection(meal: Meal) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditExpanded.toggle()
                }
                if isEditExpanded {
                    editCalories = "\(meal.calories)"
                    editProtein = String(format: "%.0f", meal.proteinG)
                    editCarbs = String(format: "%.0f", meal.carbsG)
                    editFat = String(format: "%.0f", meal.fatG)
                }
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(.caption)
                    Text("Edit values")
                        .font(DesignSystem.Typography.bodyMedium)
                    Spacer()
                    Image(systemName: isEditExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.card)
            }
            .buttonStyle(.plain)

            if isEditExpanded {
                PremiumCard(timeContext: timeContext) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        editField(label: "Calories (kcal)", value: $editCalories, color: .orange)
                        editField(label: "Protein (g)", value: $editProtein, color: .red)
                        editField(label: "Carbs (g)", value: $editCarbs, color: .blue)
                        editField(label: "Fat (g)", value: $editFat, color: .yellow)

                        Button {
                            Task { await saveEdits(meal: meal) }
                        } label: {
                            Group {
                                if isSavingEdits {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Changes")
                                        .font(DesignSystem.Typography.buttonMedium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSavingEdits)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func editField(label: String, value: Binding<String>, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(color)
                .frame(width: 80)
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

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.75 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .orange
    }

    private func foodItems(from description: String) -> [String] {
        description
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Actions

    private func startCountingAnimation(calories: Int, protein: Double, carbs: Double, fat: Double) {
        let steps = 30
        let intervalNs = UInt64(1_000_000_000 / steps)
        Task {
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: intervalNs)
                let progress = Double(step) / Double(steps)
                await MainActor.run {
                    displayCalories = Int(Double(calories) * progress)
                    displayProtein = protein * progress
                    displayCarbs = carbs * progress
                    displayFat = fat * progress
                }
            }
        }
    }

    private func saveEdits(meal: Meal) async {
        isSavingEdits = true
        var updates: [String: Any] = [:]
        if let cal = Int(editCalories) { updates["user_calories"] = cal }
        if let pro = Double(editProtein) { updates["user_protein_g"] = pro }
        if let car = Double(editCarbs) { updates["user_carbs_g"] = car }
        if let fat = Double(editFat) { updates["user_fat_g"] = fat }

        do {
            let updated = try await mealsService.updateMeal(id: meal.id, updates: updates)
            await MainActor.run {
                savedMeal = updated
                displayCalories = updated.calories
                displayProtein = updated.proteinG
                displayCarbs = updated.carbsG
                displayFat = updated.fatG
                isEditExpanded = false
                isSavingEdits = false
            }
        } catch {
            await MainActor.run {
                isSavingEdits = false
            }
        }
    }

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
