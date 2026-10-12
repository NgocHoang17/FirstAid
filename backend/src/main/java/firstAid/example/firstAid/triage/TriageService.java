package firstAid.example.firstAid.triage;

import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class TriageService {

    private static final String SAFETY_NOTICE =
            "Đây là hướng dẫn sàng lọc ban đầu, không thay thế nhân viên y tế. Gọi 115 hoặc số cấp cứu địa phương khi có nguy hiểm đến tính mạng.";

    public TriageResponse assess(TriageRequest request) {
        if (!request.conscious() && !request.breathing()) {
            return response(TriageResponse.Protocol.CPR, true, "Nạn nhân bất tỉnh và không thở.", List.of(
                    "Gọi 115 hoặc nhờ người khác gọi ngay.",
                    "Bắt đầu phác đồ CPR trong ứng dụng theo hướng dẫn đã được đơn vị y tế phê duyệt.",
                    "Chỉ di chuyển nạn nhân khi khu vực hiện trường không an toàn."));
        }
        if (!request.breathing()) {
            return response(TriageResponse.Protocol.NO_BREATHING, true, "Nạn nhân không thở hoặc thở bất thường.", List.of(
                    "Gọi 115 ngay.",
                    "Theo dõi phản ứng của nạn nhân và làm theo hướng dẫn CPR đã được phê duyệt.",
                    "Không cho nạn nhân ăn, uống hoặc dùng thuốc."));
        }
        if (request.severeBleeding()) {
            return response(TriageResponse.Protocol.SEVERE_BLEEDING, true, "Có dấu hiệu chảy máu nghiêm trọng.", List.of(
                    "Gọi 115 hoặc yêu cầu người xung quanh hỗ trợ.",
                    "Dùng vật liệu sạch ép trực tiếp lên vết thương nếu an toàn để làm vậy.",
                    "Theo dõi ý thức và nhịp thở cho đến khi có hỗ trợ y tế."));
        }
        if (!request.conscious()) {
            return response(TriageResponse.Protocol.UNCONSCIOUS, true, "Nạn nhân bất tỉnh nhưng vẫn thở.", List.of(
                    "Gọi 115 ngay.",
                    "Theo dõi liên tục nhịp thở và phản ứng của nạn nhân.",
                    "Không tự ý di chuyển nạn nhân nếu nghi ngờ chấn thương cột sống."));
        }
        return response(TriageResponse.Protocol.ASSESSMENT, false, "Nạn nhân đang tỉnh và còn thở.", List.of(
                "Đưa nạn nhân ra khỏi nguy hiểm nếu có thể làm an toàn.",
                "Chọn triệu chứng hoặc tình huống cụ thể để xem cẩm nang sơ cứu.",
                "Gọi 115 ngay nếu tình trạng xấu đi."));
    }

    private TriageResponse response(TriageResponse.Protocol protocol, boolean callEmergencyServices,
            String headline, List<String> actions) {
        return new TriageResponse(protocol, callEmergencyServices, "115", headline, actions, SAFETY_NOTICE);
    }
}
