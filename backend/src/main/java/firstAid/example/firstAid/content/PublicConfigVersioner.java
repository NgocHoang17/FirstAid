package firstAid.example.firstAid.content;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Configuration
public class PublicConfigVersioner {
    @Bean
    ApplicationRunner versionPublicConfig(JdbcTemplate db,
            @Value("${firstaid.public.locale}") String locale,
            @Value("${firstaid.public.region-code}") String publicRegion,
            @Value("${firstaid.public.emergency-number}") String emergencyNumber) {
        return args -> {
            byte[] input = (locale + "\n" + publicRegion + "\n" + emergencyNumber).getBytes(StandardCharsets.UTF_8);
            String fingerprint = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(input));
            db.update("UPDATE public_data_state SET config_fingerprint=?,data_version=?,updated_at=now() " +
                    "WHERE id=1 AND config_fingerprint<>?", fingerprint, UUID.randomUUID(), fingerprint);
        };
    }
}
