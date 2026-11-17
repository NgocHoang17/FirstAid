package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.Api;
import firstAid.example.firstAid.common.ApiFailure;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.MemoryCacheImageInputStream;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class MediaController {
    private final JdbcTemplate db;
    public MediaController(JdbcTemplate db) { this.db = db; }

    @PostMapping(value="/api/v1/admin/media", consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> upload(@RequestPart("file") MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > 5242880) throw ApiFailure.invalid("file", "Ảnh tối đa 5 MB");
        Normalized image = normalize(file.getBytes());
        UUID id = UUID.randomUUID();
        db.update("INSERT INTO media_assets(id,mime_type,width,height,content) VALUES(?,?,?,?,?)",
            id, image.mime(), image.width(), image.height(), image.bytes());
        return Api.created(Map.of("id",id.toString(),"url","/api/v1/media/"+id,
            "width",image.width(),"height",image.height()));
    }

    record Normalized(byte[] bytes, String mime, int width, int height) {}
    static Normalized normalize(byte[] bytes) throws IOException {
        try (var input = new MemoryCacheImageInputStream(new ByteArrayInputStream(bytes))) {
            var readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw ApiFailure.invalid("file", "Chỉ nhận ảnh JPEG hoặc PNG hợp lệ");
            ImageReader reader = readers.next();
            try {
                String format = reader.getFormatName().toLowerCase(Locale.ROOT);
                if (!Set.of("png","jpeg").contains(format)) throw ApiFailure.invalid("file", "Chỉ nhận JPEG hoặc PNG");
                reader.setInput(input, true, true);
                int w=reader.getWidth(0), h=reader.getHeight(0);
                if (w<=0 || h<=0 || (long)w*h>16000000) throw ApiFailure.invalid("file", "Ảnh tối đa 16 megapixel");
                BufferedImage decoded=reader.read(0);
                var output=new ByteArrayOutputStream();
                ImageIO.write(decoded,format,output);
                if(output.size()>5242880) throw ApiFailure.invalid("file", "Ảnh sau xử lý vượt 5 MB");
                return new Normalized(output.toByteArray(),"image/"+format,w,h);
            } finally { reader.dispose(); }
        } catch (javax.imageio.IIOException ex) { throw ApiFailure.invalid("file", "Không đọc được ảnh"); }
    }

    @GetMapping("/api/v1/media/{id}")
    public ResponseEntity<byte[]> image(@PathVariable UUID id, Authentication authentication) {
        boolean admin = authentication!=null && authentication.getAuthorities().stream().anyMatch(a->a.getAuthority().equals("ADMIN"));
        if (!admin) {
            Long count=db.queryForObject("SELECT count(*) FROM article_steps st JOIN articles a ON a.id=st.article_id " +
                "JOIN categories c ON c.id=a.category_id WHERE a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true " +
                "AND NOT EXISTS(SELECT 1 FROM article_references r JOIN sources s ON s.id=r.source_id WHERE r.article_id=a.id AND s.is_active=false) " +
                "AND st.images_json @> CAST(? AS jsonb)", Long.class,"[{\"media_id\":\""+id+"\"}]");
            if(count==0) throw ApiFailure.notFound();
        }
        return db.query("SELECT mime_type,content FROM media_assets WHERE id=?",(r,n)->ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(r.getString("mime_type")))
            .header("X-Content-Type-Options","nosniff")
            .header("Cache-Control","private, no-store")
            .body(r.getBytes("content")),id).stream().findFirst().orElseThrow(ApiFailure::notFound);
    }
}
