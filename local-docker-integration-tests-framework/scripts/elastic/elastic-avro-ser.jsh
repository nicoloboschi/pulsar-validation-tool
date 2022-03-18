import org.apache.pulsar.client.api.Schema;
class MyRecord {
    public int myfield;
}
MyRecord r = new MyRecord();
r.myfield = 789;

Schema<MyRecord> schema = Schema.AVRO(MyRecord.class);
byte[] ser = schema.encode(r);
java.nio.file.Files.write(new java.io.File("ser.bin").toPath(), ser);
/exit