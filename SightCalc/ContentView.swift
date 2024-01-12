import SwiftUI
//import Combine
import AVFoundation

enum BorderStyle {
    case none, line, bezel, roundedRect
}

public extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}

extension View {
    func Print(_ vars: Any...) -> some View {
        for v in vars { print(v) }
        return EmptyView()
    }
}

//Navigation for access to Help page
struct ContentView: View {
    var body: some View {
        NavigationView {
            MainContentView()
                .navigationBarItems(trailing: NavigationLink(destination: HelpView()) {
                    Image(systemName: "questionmark.circle").foregroundColor(.white)
                })
        }.navigationViewStyle(StackNavigationViewStyle())  //otherwise, runs in sidebar on iPad
    }
}

struct CustomInputView: UIViewRepresentable {
    @Binding var text: String
    @Binding var backgroundColor: Color // Binding for background color
    @Binding var borderStyle: BorderStyle  //Binding for border style

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomInputView
        
        init(_ parent: CustomInputView) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            self.parent.text = newText
            return false
        }
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.inputView = UIView() // Replace system keyboard with a blank view
        textField.backgroundColor = UIColor(white: 0.9, alpha: 1.0) // Set background color
        textField.borderStyle = convertBorderStyle(borderStyle) // Set border style
        //textField.textColor = UIColor(.white)
        textField.layer.cornerRadius = 8.0 // Apply corner radius
        //        textField.returnKeyType = .next // Set return key type
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.backgroundColor = UIColor(backgroundColor) // Update background color
        uiView.borderStyle = convertBorderStyle(borderStyle) // Update border style
        uiView.textColor = UIColor(.black)  //Sets the input text color (form foreground overrides)
        uiView.textAlignment = .right
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Helper method to convert SwiftUI BorderStyle to UITextField.BorderStyle
     private func convertBorderStyle(_ style: BorderStyle) -> UITextField.BorderStyle {
         switch style {
         case .none:
             return .none
         case .line:
             return .line
         case .bezel:
             return .bezel
         case .roundedRect:
             return .roundedRect
         }
     }
} //end of CustomInputView

struct CustomKeyboard: View {
    @Binding var focusedField: Int?
    @Binding var textFields: [String]
    @State private var LHA: String = ""
    @State private var LHAminutes: String = ""
    @State private var Latitude: String = ""
    @State private var LatMinutes: String = ""
    @State private var Declination: String = ""
    @State private var DecMinutes: String = ""
    @State private var DegreesMinutes: String = ""

    // Return different color for operators and numbers.
    func getBackground(str:String) -> Color {
        
        if checkIfOperator(str: str) {
            return Color.orange
        }
        return Color.blue
    }

    // Return different font sizes for operators and numbers.
    func getFontSize(btnTxt: String) -> CGFloat {
        
        if checkIfOperator(str: btnTxt) {
            return 24
        }
        return 24
    }

    // Return different width for operators and numbers.
    func getBtnWidth(str: String) -> CGFloat {
        
        if checkIfOperator(str: str) {
            return 90
        }
        return 60
    }
    
    // This function returns if the passed argument is a operator or not.
    func checkIfOperator(str:String) -> Bool {
        
        if str == "Enter" || str == "CE" || str == "C" || str ==  "°" {
            return true
        }
        return false
    }
    
    //Button title array
    let rows = [
        ["7", "8", "9","Enter"],
        ["4", "5", "6", "CE"],
        ["1", "2", "3", "C"],
        ["-", "0", ".", "°"]
    ]
    
    //Display keyboard buttons
     var body: some View {
         
             VStack(alignment: .leading) {
                 //Text(" ")                      //Spacing above keys in pre iOS 16 ver
                 ForEach(rows, id: \.self) { row in
                     HStack(alignment: .top, spacing: 10) {
                         ForEach(row, id: \.self) { column in
                             Button(action: {
                                 if checkIfOperator(str: column){
                                     switch column {
                                     case "Enter":
                                         self.moveFocusToNextField()
                                     case"CE":
                                         self.clearEntry()
                                     case "C":
                                         clearAll()
                                     case "°":
                                         addMinutes()
                                     default:
                                         break
                                     }
                                 }
                                 else
                                 {
                                     switch column{
                                     case "-":
                                         guard let focusedField = focusedField else { return }
                                         if (((focusedField == 1) || (focusedField == 3) || (focusedField == 5)) && textFields[focusedField - 1] == "") {
                                             self.appendCharacter("-")
                                         }else{
                                             AudioServicesPlaySystemSound(1103)
                                         }
                                     case ".":
                                         guard let focusedField = focusedField else { return }
                                         if !textFields[focusedField - 1].contains(".") {
                                             self.appendCharacter(".")
                                         }else{
                                             AudioServicesPlaySystemSound(1103)
                                         }
                                         
                                     default:
                                         self.appendCharacter(column)
                                     }
                                 }
                             }, label: {
                                 Text(column)
                                 .font(.system(size: getFontSize(btnTxt: column)))
                                 .frame(width: getBtnWidth(str:column), height: 40)
                                 .foregroundColor(.white)
                                 .background(getBackground(str: column))
                                 .cornerRadius(10)
                                 .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                                 .shadow(color: .gray, radius: 2, x: 6, y: 4)
                                 
                             }) //end of button action
                         } //end of 'for each' column
                     } //end HStack
                 } //end 'for each' row
             }  //.frame(   maxHeight: 200,  alignment: .bottom)   //end VStack
     }      //end keyboard view
        
    func appendCharacter(_ character: String) {
        guard let focusedField = focusedField else { return }
        let keyRange = 1...6
        if keyRange.contains (focusedField){
            if textFields[focusedField - 1].count > 9
            {
                AudioServicesPlaySystemSound(1103)  //user typed too many chars
                return
            }
        textFields[focusedField - 1] += character
        AudioServicesPlaySystemSound(1104)
        }
        else{
            return
        }
    }
    
    func moveFocusToNextField() {
        guard let focusedField = focusedField else { return }
        let keyRange = 1...6
        if keyRange.contains (focusedField){
            if (Double(textFields[focusedField - 1]) ?? 360 > 360.0){
                textFields[focusedField - 1] = "Over 360!"
                return
            }
            if focusedField < textFields.count {
                self.focusedField = focusedField + 1
            }
            else{
                self.focusedField = 1
            }
            AudioServicesPlaySystemSound(1104)
        }
        else{
            return
        }
    }
            
    func clearEntry() {
        guard let focusedField = focusedField else { return }
        let keyRange = 1...6
        if keyRange.contains (focusedField){
            textFields[focusedField - 1] = ""
            AudioServicesPlaySystemSound(1104)
        }
        else{
            return
        }
    }
    
    func clearAll() {
        textFields = Array(repeating: "", count: textFields.count)
        self.focusedField = 1
        AudioServicesPlaySystemSound(1104)
    }
    
    func addMinutes() {
        //Convert minutes to degrees and add to degrees field
        guard let focusedField = focusedField else { return }
        let keyRange = 1...6
        if keyRange.contains (focusedField){
            if (((focusedField == 1) || (focusedField == 3) || (focusedField == 5))){
                if textFields[focusedField] != "" { //Assure minutes > 0 {
                    textFields[focusedField - 1] = String(format: "%.5f", degAndMin)
                }
            }
            else{ //saw in minutes field
                if focusedField < 2 { return }
                if textFields[focusedField - 1] != "" { //Assure minutes > 0
                    textFields[focusedField - 2] = String(format: "%.5f", minAndDeg)
                }
            }
        }
        else{
            return
        }
        
    }
    
    var degAndMin: Double {     //if in Degree field
        guard let focusedField = focusedField else { return 0 }
        guard let ff_1 = Double(textFields[focusedField - 1]) else { return 0 }
        guard let ff_0 = Double(textFields[focusedField ]) else { return 0 }
        var ffdegrees = ff_1 + (ff_0 / 60.0)
        if (ff_1 < 0) { ffdegrees = ff_1 - (ff_0 / 60.0) }
        textFields[focusedField ] = ""
        return (ffdegrees)
    }
    var minAndDeg: Double {     //if in minutes
        guard let focusedField = focusedField else { return 0 }
        guard let ff_0 = Double(textFields[focusedField - 1]) else { return 0 }  //mins
        guard let ff_1 = Double(textFields[focusedField - 2]) else { return ff_0 / 60.0}  //degrees
        var ffdegrees = ff_1 + (ff_0 / 60.0)
        if (ff_1 < 0) { ffdegrees = ff_1 - (ff_0 / 60.0) }
        textFields[focusedField - 1] = ""
        return (ffdegrees)
    }
    }

// Primary View

struct MainContentView: View {

    init(){
        //UITableView.appearance().backgroundColor = .clear   //only for iOS 15 or earlier
        UITableViewHeaderFooterView.appearance().tintColor = UIColor.clear
    }
    @Environment(\.colorScheme) var colorScheme
    @State var value = ""
    @State private var focusedField: Int? = 1
    @State private var textFields: [String] = Array(repeating: "", count: 6)
    @State private var fieldBackgroundColors: [Color] = [
        .white, .yellow, .blue, .green, .orange, .pink, .purple, .black // Example colors
    ]
    @State private var fieldBorders: [BorderStyle] = [.none, .roundedRect, .line, .bezel]
    @State private var LHA: Int = 0
    @State private var LHAminutes: Int = 1
    @State private var Latitude: Int = 2
    @State private var LatMinutes: Int = 3
    @State private var Declination: Int = 4
    @State private var DecMinutes: Int = 5
    
    // Helper functions for clarity
    func deg2rad(degrees : Double) -> Double
    {
        return degrees * Double.pi / 180.0
    }

    func rad2deg(radians : Double) -> Double
    {
        return radians * 180.0 / Double.pi
    }

    func deg2min(degrees: Double) -> Double
    {
        return degrees / 60.0
    }
    
    // Computed properties
    
     var dec_rad : Double {
         guard let strDec = Double(textFields[Declination]) else { return 0 }
         guard var strDecmin = Double(textFields[DecMinutes]) else { return deg2rad(degrees: strDec) }
         if (strDec < 0) { strDecmin = -strDecmin }
         return deg2rad(degrees: strDec + strDecmin/60.0)
     }
     
     var lha_rad : Double {
         guard let strLHA = Double(textFields[LHA])  else { return 0 }
         guard var strLHAmin = Double(textFields[LHAminutes])  else { return deg2rad(degrees: strLHA) }
         if (strLHA < 0){ strLHAmin = -strLHAmin }
         return deg2rad(degrees: strLHA + strLHAmin/60.0)
     }
     
     var lat_rad : Double {
         guard let strLat = Double(textFields[Latitude]) else { return 0 }
         guard var strLatmin = Double(textFields[LatMinutes]) else { return deg2rad(degrees: strLat) }
         if (strLat < 0){ strLatmin = -strLatmin }
         return deg2rad(degrees: strLat + strLatmin/60.0)
     }
     
     var hc_rad : Double {
         let hc_rad = asin((cos(lha_rad) * cos(abs(lat_rad)) * cos(dec_rad)) + (sin(abs(lat_rad)) * sin(dec_rad)))
         return hc_rad
     }
     
     var hc_str : String {
         if (valid)
         {
             let hc = hc_rad * 180.0 / Double.pi;
             return String(hc)
         }
         else
         {
             return "Bad hc"
         }
     }
    
     var z_value : String {
         
         let z_rad = acos((sin(dec_rad) - (sin(abs(lat_rad)) * sin(hc_rad))) / (cos(abs(lat_rad)) * cos(hc_rad)));
         
         let z_deg = z_rad * 180.0 / Double.pi;
         
         return String(z_deg)
     }
     
     var zn_value : String {
         
         if (lha_rad > Double.pi)
         {
             if (lat_rad > 0)
             {
                 return z_value
             }
             else
             {
                 return String(180.0 - Double(z_value)!)
             }
         }
         else
         {
             if (lat_rad > 0)
             {
                 return String(360.0 - Double(z_value)!)
             }
             else
             {
                 return String(180.0 + Double(z_value)!)
             }
         }
     }
     
     var hc_min : String {
         let hc = modf(hc_rad * 180.0 / Double.pi);
         //return String(rad2deg(radians: Double(hc_parts.1 )))
         return String(Double(hc.1 * 60.0))
     }
    
    var  intdeg : Double
    {
        guard let hc_int = Double(hc_str) else {return 0}
        let hc_int2 = modf(hc_int).0
        return hc_int2
    }
     
     var valid : Bool {
         return true
     }
    // These colors depend on light/dark modes of device
    var bkgcolor : Color {
        return (colorScheme == .light) ? Color.teal : Color.black
    }
    
    var forcolor : Color {
        return (colorScheme == .light) ? Color.black : Color.white
    }
    
    var titlecolor : Color {
        return (colorScheme == .light) ? Color.white : Color.white
    }
    
    var body: some View {
        
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            
            VStack {
                Text("Sight Reduction Calculator").font(.system(size: 25, weight: .bold))
                    .foregroundColor(titlecolor)
                    .padding()

                Form        //Section() Replaces Form in pre-iOS 16 ver
                {
                    //Results Section
                    Section("Intercept and Azimuth by Law of Cosines")
                    {
                        //Result Fields
                        VStack(alignment: .leading, spacing:10 ){
                            HStack{
                                Text("Hc: ").font(.system(size:20, weight: .bold))
                                Text("\(String(format: "%.5f", Double(hc_str) ?? 0.0))") + Text("°")
                                Text("\(String(intdeg))") + Text("°")
                                Text(" \(String(format: "%.1f", Double(hc_min) ?? 0))") + Text("\'  ")
                                
                            }.foregroundColor(forcolor)
                            
                            HStack{
                                Text("Z:    ").font(.system(size:20, weight: .bold))
                                Text("\(String(format: "%.1f", Double(z_value) ?? 0.0))") + Text("°")
                            }.foregroundColor(forcolor)
                            HStack{
                                Text("Zn: ").font(.system(size:20, weight: .bold))
                                Text("\(String(format: "%.0f", Double(zn_value) ?? 0.0))") + Text("°")
                            }.foregroundColor(forcolor)
                        }   //end VStack - result fields
                        
                    }  // end section
                    //.background(bkgcolor)
                    
                    //Input Section
                    //  none, line, bezel, roundedRect
                    Section("                              Degrees                     Minutes"){
                        HStack {
                            Text(" LHA:")
                            if focusedField == 1 {
                                CustomInputView(text: $textFields[0], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 1 }
                            }
                            else{
                                CustomInputView(text: $textFields[0], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 1 }
                            }
                            if focusedField == 2 {
                                CustomInputView(text: $textFields[1], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 2 }
                            }
                            else{
                                CustomInputView(text: $textFields[1], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 2 }
                            }
                        }
                        .foregroundColor(forcolor)
                        
                        HStack {
                            Text(" Lat: ")
                            if focusedField == 3 {
                                CustomInputView(text: $textFields[2], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 3 }
                            }
                            else {
                                CustomInputView(text: $textFields[2], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 3 }
                            }
                            if focusedField == 4 {
                                CustomInputView(text: $textFields[3], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 4 }
                            }
                            else {
                                CustomInputView(text: $textFields[3], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 4 }
                            }
                        }
                        .foregroundColor(forcolor)
                        HStack {
                            Text(" Dec:")
                            
                            if focusedField == 5 {
                                CustomInputView(text: $textFields[4], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 5 }
                            }
                            else {
                                CustomInputView(text: $textFields[4], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 5 }
                            }
                            if focusedField == 6 {
                                CustomInputView(text: $textFields[5], backgroundColor: $fieldBackgroundColors[1], borderStyle: $fieldBorders[2])
                                    .onTapGesture { self.focusedField = 6 }
                            }
                            else{
                                CustomInputView(text: $textFields[5], backgroundColor: $fieldBackgroundColors[0], borderStyle: $fieldBorders[0])
                                    .onTapGesture { self.focusedField = 6 }
                            }
                        } //end of HStack
                        .foregroundColor(forcolor)
                    } //end of Section
                    
                    //.background(bkgcolor)
                } //end of Form
                .frame(maxHeight: 380)    //Set height of Data Entry form
                .foregroundColor(titlecolor)
                //.background(bkgcolor)       //should work for iOS 15 but doesnt
               // .modify {
                 //   if #available(iOS 16.0, *){
                     //   .scrollContentBackground(.hidden)
                   // }
                //}
                .scrollContentBackground(.hidden)  //only in iOS 16
                
                CustomKeyboard(focusedField: $focusedField, textFields: $textFields)
                    
            }
            //end vstack .foregroundColor(Color.gray) -affects results & labels

            }// end of ZStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(bkgcolor)
        } //End of body
    
}  //end of MainContent view
    
struct HelpView: View {
    var body: some View {
        ScrollView{
            ZStack{
                VStack {
                    Text("Sight Calc 2.0")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 350,  alignment: .center)
                    
                    Text("Sight Calc 2.0 is a specialized calculator for sight reductions via the 'Law of Cosines' method for students of celestial navigation. As it's main purpose is as an educational tool, it does not use Nautical Almanac data, so you must first compute Local Hour Angle and declination, and determine your approximate latitude. A good source for more info is America's Boating Club®, www.americasboatingclub.org.\n")
                        .foregroundColor(.white)
                    Text("Enter data either in degrees with a decimal fraction, or degrees and minutes.  The 'Enter' key will move to the next field, or you may select any field directly. The active field has a yellow background.\n")
                        .foregroundColor(.white)
                    Text("IMPORTANT: Enter North Latitude as a positive number, and South Latitude as NEGATIVE.  Sight Calc will take the absolute value of Latitude in the law of cosines forumula, but needs the hemisphere to calculate Zn.  Declination is positive if Latitude and Declination are the same sense (both North or both South).  If different, enter declination as negative.\n")
                        .foregroundColor(.yellow)
                    
                    Text("To do repeated calculations with some of the same numbers, just enter the changed numbers - results are continuously calculated. To start over, press 'C' to clear everything.\n ")
                        .foregroundColor(.white)
                    
                    Text("Please report any bugs or suggestions to: ")
                        .foregroundColor(.white)
                    Text("sightcalc@nuvocom.com")
                        .foregroundColor(.black)
                    Text("\nNot for use in actual navigation.")
                        .foregroundColor(.black)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }  //end VStack

                .padding()
            }//end zstack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.teal)
        }// end of scrollview
        .background(.teal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
