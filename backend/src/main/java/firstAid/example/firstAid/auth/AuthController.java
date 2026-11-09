package firstAid.example.firstAid.auth;

import firstAid.example.firstAid.common.Api;
import firstAid.example.firstAid.common.ApiFailure;
import firstAid.example.firstAid.common.Checks;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/auth")
public class AuthController {
    private final AuthenticationManager manager;
    private final JdbcTemplate db;
    private final LoginLimiter limiter;
    private final HttpSessionSecurityContextRepository sessions = new HttpSessionSecurityContextRepository();

    public AuthController(AuthenticationManager manager, JdbcTemplate db, LoginLimiter limiter) {
        this.manager = manager; this.db = db; this.limiter = limiter;
    }

    @GetMapping("/csrf")
    public Map<String, Object> csrf(CsrfToken token) {
        return Api.ok(Map.of("token", token.getToken(), "header_name", token.getHeaderName()));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody Map<String, Object> body, HttpServletRequest request, HttpServletResponse response) {
        String username = Checks.text(body, "username", 100, true);
        Object rawPassword = body.get("password");
        if (!(rawPassword instanceof String password) || password.isEmpty() || password.length() > 200)
            throw ApiFailure.invalid("password", "Mật khẩu không hợp lệ");
        limiter.check(request.getRemoteAddr());
        try {
            Authentication auth = manager.authenticate(new UsernamePasswordAuthenticationToken(username, password));
            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(auth);
            SecurityContextHolder.setContext(context);
            request.getSession(true);
            sessions.saveContext(context, request, response);
            return Api.ok(admin(username));
        } catch (AuthenticationException ex) {
            throw new ApiFailure(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Thông tin đăng nhập không đúng");
        }
    }

    @GetMapping("/me")
    public Map<String, Object> me(Authentication auth) { return Api.ok(admin(auth.getName())); }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        if (request.getSession(false) != null) request.getSession(false).invalidate();
        SecurityContextHolder.clearContext();
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> admin(String username) {
        return db.query("SELECT id,username FROM admin_users WHERE username=? AND enabled=true",
                (rs, n) -> Map.<String, Object>of("id", rs.getString("id"), "username", rs.getString("username"), "role", "ADMIN"), username)
                .stream().findFirst().orElseThrow(ApiFailure::notFound);
    }
}
