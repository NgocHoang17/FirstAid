package firstAid.example.firstAid.content;

import firstAid.example.firstAid.common.ApiFailure;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class MediaControllerTest {
    @Test void decodesAndNormalizesPngInsteadOfTrustingTheFilename() throws Exception {
        var bytes=new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(20,12,BufferedImage.TYPE_INT_RGB),"png",bytes);
        bytes.write("untrusted trailing data".getBytes());
        var image=MediaController.normalize(bytes.toByteArray());
        assertEquals("image/png",image.mime());
        assertEquals(20,image.width()); assertEquals(12,image.height());
        assertTrue(image.bytes().length<bytes.size());
    }
    @Test void rejectsSvgAndArbitraryBytes() {
        assertThrows(ApiFailure.class,()->MediaController.normalize("<svg onload='alert(1)'/>".getBytes()));
        assertThrows(ApiFailure.class,()->MediaController.normalize(new byte[]{1,2,3}));
    }
}
