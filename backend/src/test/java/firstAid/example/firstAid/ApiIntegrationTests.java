package firstAid.example.firstAid;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class ApiIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void triageReturnsCprProtocolForUnconsciousNonBreathingVictim() throws Exception {
        mockMvc.perform(post("/api/v1/triage")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conscious\":false,\"breathing\":false,\"severeBleeding\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.protocol").value("CPR"))
                .andExpect(jsonPath("$.callEmergencyServices").value(true))
                .andExpect(jsonPath("$.emergencyNumber").value("115"));
    }

    @Test
    void triageRejectsIncompletePayload() throws Exception {
        mockMvc.perform(post("/api/v1/triage")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"conscious\":true}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void handbookSearchFindsBurnArticle() throws Exception {
        mockMvc.perform(get("/api/v1/handbook").param("query", "bỏng"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value("thermal-burn"));
    }

    @Test
    void nearbyFacilitiesAreSortedByDistance() throws Exception {
        mockMvc.perform(get("/api/v1/facilities/nearby")
                        .param("latitude", "10.7769")
                        .param("longitude", "106.7009"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value("sample-1"))
                .andExpect(jsonPath("$[0].distanceKm").value(0.0));
    }
}
