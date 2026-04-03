# Astra | Centralized Academic Assessment System

A high-performance, cross-platform quiz management system built with **Flutter** and **Firebase**. Astra streamlines the examination workflow by providing distinct, synchronized environments for Administrators, Faculty, and Students.

## 🏛️ System Architecture

The platform is divided into three core modules to ensure granular access control and data integrity:

### 1. Admin Dashboard (The Controller)
* **Identity & Access Management:** Global control over Student and Faculty onboarding.
* **Academic Mapping:** Assign specific classes and batches to Faculty members.
* **Institutional Oversight:** High-level view of all quiz results and attendance metrics across the college.

### 2. Faculty Dashboard (The Evaluator)
* **Quiz Orchestration:** Conduct and manage quizzes for assigned classes.
* **Live Monitoring:** Track student participation in real-time.
* **Grade Management:** Review student submissions and finalize grading workflows.

### 3. Student Dashboard (The Participant)
* **Upcoming Assessments:** A minimalist feed of scheduled quizzes.
* **Precision Timing:** Integrated countdown timers for upcoming exam windows.
* **Performance History:** Comprehensive review of past results and feedback.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Material 3 Design)
* **Backend & Database:** [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore)
* **Authentication:** [Firebase Auth](https://firebase.google.com/docs/auth)
* **State Management:** Provider / Riverpod (Edit as per your implementation)

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK: `^3.0.0`
* Dart SDK: `^3.0.0`
* A Firebase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/yourusername/quiz.git](https://github.com/yourusername/quiz.git)
   cd quiz
   
2. **Dependencies:**
   Run the following command to pull all required packages:
   ```bash
   flutter pub get
   
3. Firebase Configuration:
   * Create a new project in the Firebase Console.
   * Initialize Firebase in the project:
    ```bash
   flutterfire configure
* Ensure Firestore and Authentication services are enabled in your Firebase project console.

4. Launch:
   Connect your emulator or device and run:
   ```bash
   flutter run

## Roadmap:
   We are continuously evolving Astra to better serve the academic community:
   [ ] **Phase 1: Analytics Dashboard** - Implement visual grade distributions for Admins.
   [ ] **Phase 2: Proctored Mode** - Integrate detection for tab-switching/app-minimizing during active quizzes.
   [ ] **Phase 3: Export Features** - Add functionality to export quiz results as PDF/CSV reports.
   [ ] **Phase 4: Dark Mode** - Refine the luxury-tech aesthetic with a dedicated system-wide dark theme.

## License 
This project is licensed under the MIT License. You are free to use, modify, and distribute this software for educational or commercial purposes.
See the LICENSE file for more details.


   
