package firstAid.example.firstAid.assistant;

import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class EmergencyPolicy {
    // Conservative first gate for explicit current incidents. It does not select a technique or diagnose.
    public boolean clearCurrentIncident(String message) {
        String text = message.toLowerCase(Locale.ROOT);
        boolean current = text.contains("đang ") || text.contains("ngay bây giờ")
                || text.contains("trước mặt tôi") || text.contains("bên cạnh tôi");
        boolean educational = text.contains("đang học") || text.contains("tìm hiểu")
                || text.contains("giả sử") || text.contains("ví dụ") || text.contains("bài học");
        boolean danger = text.contains("không thở") || text.contains("bất tỉnh")
                || text.contains("không đáp ứng") || text.contains("chảy máu ồ ạt");
        return current && danger && !educational;
    }
}
