//
//  MealLogView.swift
//  Your Daily Dose
//
//  Photo-based meal logging flow: camera-first → auto meal type → AI analysis → animated results → review → save.
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

    // Animated macro display values
    @State private var displayedCalories: Int = 0
    @State private var displayedProtein: Double = 0
    @State private var displayedCarbs: Double = 0
    @State private var displayedFat: Double = 0

    // Edit values section
    @State private var showEditValues = false
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    @State private var isSavingEdit = false

    private let mealsService: MealsServiceProtocol = MealsService()
    private let timeContext: DesignSystem.TimeContext = .neutral
    private let dateString: String

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)

        // Auto-detect meal type from time of day
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 {
            self._mealType = State(initialValue: "breakfast")
        } else if hour < 15 {
            self._mealType = State(initialValue: "lunch")
        } else if hour < 21 {
            self._mealType = State(initialValue: "dinner")
        } else {
            self._mealType = State(initialValue: "snack")
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
                // Auto-open camera on first appear if no image yet
                if !hasAutoOpenedCamera && selectedImage == nil {
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
                        // Auto-analyze after selecting from library
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
                                .font(DesignSystem.Typography.displaySmall)
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
                            HapticManager.selectionChanged()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(DesignSystem.Typography.headlineLarge)
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
                        .font(DesignSystem.Typography.displayMedium)
                        .foregroundColor(.green)
                    Text("Meal Logged!")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                // Photo with confidence ring
                if let image = selectedImage {
                    let confidence = meal.aiConfidence ?? 0
                    let ringColor: Color = confidence >= 0.75 ? .green : confidence >= 0.5 ? .yellow : .orange
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 200)
                        .clipped()
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .strokeBorder(ringColor, lineWidth: 3)
                        )
                }

                // Food description as scrollable tag chips
                if let desc = meal.foodDescription, !desc.isEmpty {
                    let tags = desc
                        .components(separatedBy: CharacterSet(charactersIn: ",;"))
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.Colors.cardBackground)
                                    .cornerRadius(DesignSystem.CornerRadius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                            .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 1)
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
                                Text(String(format: "%.0f%% confidence", conf * 100))
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
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
                    animateMacros(meal: meal)
                }

                // Edit values — collapsed by default
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEditValues.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Edit values")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                            Image(systemName: showEditValues ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    .buttonStyle(.plain)

                    if showEditValues {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                editField(label: "Calories", text: $editCalories, unit: "kcal")
                                editField(label: "Protein", text: $editProtein, unit: "g")
                            }
                            HStack(spacing: DesignSystem.Spacing.md) {
                                editField(label: "Carbs", text: $editCarbs, unit: "g")
                                editField(label: "Fat", text: $editFat, unit: "g")
                            }
                            Button {
                                Task { await saveEdits(meal: meal) }
                            } label: {
                                Group {
                                    if isSavingEdit {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Text("Save")
                                            .font(DesignSystem.Typography.buttonMedium)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingEdit)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.card)
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

    private func editField(label: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            HStack {
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .font(DesignSystem.Typography.bodyMedium)
                Text(unit)
                    .font(DesignSystem.Typography.metadata)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 8)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.button)
        }
        .frame(maxWidth: .infinity)
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
                // Pre-fill edit fields with AI values
                editCalories = "\(meal.calories)"
                editProtein = String(format: "%.0f", meal.proteinG)
                editCarbs = String(format: "%.0f", meal.carbsG)
                editFat = String(format: "%.0f", meal.fatG)
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

    private func animateMacros(meal: Meal) {
        let targetCalories = meal.calories
        let targetProtein = meal.proteinG
        let targetCarbs = meal.carbsG
        let targetFat = meal.fatG
        let steps = 20
        let interval: Double = 0.04
        Task {
            for step in 1...steps {
                let progress = Double(step) / Double(steps)
                await MainActor.run {
                    displayedCalories = Int(Double(targetCalories) * progress)
                    displayedProtein = targetProtein * progress
                    displayedCarbs = targetCarbs * progress
                    displayedFat = targetFat * progress
                }
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            await MainActor.run {
                displayedCalories = targetCalories
                displayedProtein = targetProtein
                displayedCarbs = targetCarbs
                displayedFat = targetFat
            }
        }
    }

    private func saveEdits(meal: Meal) async {
        isSavingEdit = true
        var updates: [String: Any] = [:]
        if let cal = Int(editCalories) { updates["user_calories"] = cal }
        if let p = Double(editProtein) { updates["user_protein_g"] = p }
        if let c = Double(editCarbs) { updates["user_carbs_g"] = c }
        if let f = Double(editFat) { updates["user_fat_g"] = f }

        if !updates.isEmpty {
            if let updated = try? await mealsService.updateMeal(id: meal.id, updates: updates) {
                await MainActor.run {
                    savedMeal = updated
                    displayedCalories = updated.calories
                    displayedProtein = updated.proteinG
                    displayedCarbs = updated.carbsG
                    displayedFat = updated.fatG
                    showEditValues = false
                }
            }
        }
        await MainActor.run { isSavingEdit = false }
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
