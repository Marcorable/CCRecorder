import Foundation

extension TimeInterval {
    
    var displayTime: String {
        let oneMinutePerSeconds = 60
        let oneHourPerSeconds = 60 * oneMinutePerSeconds
        
        var seconds = Int(ceil(self))
        var hours = 0
        var minutes = 0
        
        if seconds > oneHourPerSeconds {
            hours = seconds / oneHourPerSeconds
            seconds -= hours * oneHourPerSeconds
        }
        
        if seconds > oneMinutePerSeconds {
            minutes = seconds / oneMinutePerSeconds
            seconds -= minutes * oneMinutePerSeconds
        }
        
        var formattedString = ""
        if hours > 0 {
            formattedString = String(format: "%02d:", hours)
        }
        formattedString += String(format: "%02d:", minutes)
        formattedString += String(format: "%02d", seconds)
        return formattedString
    }
    
}
