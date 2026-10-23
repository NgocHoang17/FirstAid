package firstAid.example.firstAid.handbook;

public class HandbookNotFoundException extends RuntimeException {
    public HandbookNotFoundException(String id) {
        super("Handbook article not found: " + id);
    }
}
