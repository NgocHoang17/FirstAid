package firstAid.example.firstAid.assistant;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class EmergencyPolicyTest {
    private final EmergencyPolicy policy = new EmergencyPolicy();

    @Test
    void redirectsExplicitCurrentIncidentWithoutChoosingAnArticle() {
        assertTrue(policy.clearCurrentIncident("Người trước mặt tôi đang không thở"));
        assertTrue(policy.clearCurrentIncident("Bạn tôi đang bất tỉnh"));
    }

    @Test
    void leavesEducationalQuestionForRagPolicy() {
        assertFalse(policy.clearCurrentIncident("Tôi đang học về người không thở trong bài học"));
        assertFalse(policy.clearCurrentIncident("Giải thích kiến thức về bất tỉnh"));
    }
}
