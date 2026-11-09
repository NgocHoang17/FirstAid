package firstAid.example.firstAid.auth;

import firstAid.example.firstAid.common.Api;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.csrf.HttpSessionCsrfTokenRepository;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.ObjectMapper;

@Configuration
public class SecurityConfig {
    @Bean
    PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }

    @Bean
    UserDetailsService admins(JdbcTemplate db) {
        return username -> db.query("SELECT username,password_hash,enabled FROM admin_users WHERE username=?",
                        (rs, n) -> User.withUsername(rs.getString("username")).password(rs.getString("password_hash"))
                                .authorities("ADMIN").disabled(!rs.getBoolean("enabled")).build(), username)
                .stream().findFirst().orElseThrow(() -> new org.springframework.security.core.userdetails.UsernameNotFoundException("Unknown admin"));
    }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    SecurityFilterChain security(HttpSecurity http, ObjectMapper json) throws Exception {
        HttpSessionCsrfTokenRepository csrf = new HttpSessionCsrfTokenRepository();
        csrf.setHeaderName("X-CSRF-TOKEN");
        http.cors(cors -> {}).csrf(c -> c.csrfTokenRepository(csrf)
                        .ignoringRequestMatchers(request -> request.getMethod().equals("POST")
                                && request.getServletPath().equals("/api/v1/assistant/query")))
                .httpBasic(AbstractHttpConfigurer::disable).formLogin(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(a -> a
                        .requestMatchers("/api/v1/admin/auth/csrf", "/api/v1/admin/auth/login").permitAll()
                        .requestMatchers("/api/v1/admin/**").hasAuthority("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/v1/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/assistant/query").permitAll()
                        .anyRequest().denyAll())
                .exceptionHandling(e -> e
                        .authenticationEntryPoint((request, response, ex) -> write(json, response, 401, "AUTH_REQUIRED", "Cần đăng nhập Admin"))
                        .accessDeniedHandler((request, response, ex) -> write(json, response, 403,
                                ex instanceof org.springframework.security.web.csrf.CsrfException ? "CSRF_INVALID" : "ACCESS_DENIED",
                                "Không có quyền hoặc CSRF token không hợp lệ")));
        return http.build();
    }

    private void write(ObjectMapper json, HttpServletResponse response, int status, String code, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json.writeValueAsString(Api.error(code, message, List.of())));
    }

    @Bean
    CorsConfigurationSource cors(@Value("${firstaid.cors.allowed-origin}") String origin) {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(List.of(origin));
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Content-Type", "X-CSRF-TOKEN", "If-None-Match"));
        cfg.setExposedHeaders(List.of("ETag"));
        cfg.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", cfg);
        return source;
    }
}
