package firstAid.example.firstAid.auth;

import firstAid.example.firstAid.common.ApiFailure;
import java.util.ArrayDeque;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class LoginLimiter {
    private final ConcurrentHashMap<String, ArrayDeque<Long>> attempts = new ConcurrentHashMap<>();
    private final AtomicInteger count = new AtomicInteger();

    public void check(String address) {
        long now = System.currentTimeMillis();
        ArrayDeque<Long> queue = attempts.computeIfAbsent(address, key -> new ArrayDeque<>());
        synchronized (queue) {
            while (!queue.isEmpty() && queue.peekFirst() < now - 600_000) queue.removeFirst();
            if (queue.size() >= 10) throw new ApiFailure(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", "Thử đăng nhập quá nhiều lần");
            queue.addLast(now);
        }
        if (count.incrementAndGet() % 100 == 0) attempts.entrySet().removeIf(e -> {
            synchronized (e.getValue()) { return e.getValue().isEmpty() || e.getValue().peekLast() < now - 600_000; }
        });
    }
}
