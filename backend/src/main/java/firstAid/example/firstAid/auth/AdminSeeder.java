package firstAid.example.firstAid.auth;

import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminSeeder {
    @Bean
    ApplicationRunner seedAdmin(JdbcTemplate db, PasswordEncoder encoder,
            @Value("${ADMIN_SEED_USERNAME:}") String username, @Value("${ADMIN_SEED_PASSWORD:}") String password) {
        return args -> {
            if (username.isBlank() && password.isBlank()) return;
            if (username.isBlank() || password.isBlank() || password.length() < 12)
                throw new IllegalStateException("ADMIN_SEED_USERNAME and a password of at least 12 characters are required together");
            db.update("INSERT INTO admin_users(id,username,password_hash,enabled) VALUES(?,?,?,true) ON CONFLICT(username) DO NOTHING",
                    UUID.randomUUID(), username, encoder.encode(password));
        };
    }
}
