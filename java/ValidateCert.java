// ValidateCert.java
//
// Will validate a given X.509 certificate against a specific cacerts file.
//
// To compile: javac ValidateCert.java
//
// To run: java ValidateCert <cacerts> <certfile.pem>

import java.io.File;
import java.io.FileInputStream;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.CertPath;
import java.security.cert.CertPathValidator;
import java.security.cert.CertPathValidatorResult;
import java.security.cert.PKIXCertPathValidatorResult;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;

public class ValidateCert {
  private static String PASSWORD = "changeit";

  public static void main(String[] argv) throws Exception {
    if (argv.length != 2) {
      System.err.println("Usage: java ValidateCert <cacerts> <certfile.pem>");
      System.exit(1);
    }

    String cacerts = argv[0];
    String certfile = argv[1];

    // Load cacerts
    FileInputStream is = new FileInputStream(cacerts);
    KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
    keystore.load(is, PASSWORD.toCharArray());

    // Load certificate chain to validate
    CertificateFactory cf = CertificateFactory.getInstance("X.509");
    List<Certificate> mylist = new ArrayList<Certificate>();
    FileInputStream in = new FileInputStream(certfile);
    while (in.available() > 0) {
      Certificate c = cf.generateCertificate(in);
      mylist.add(c);
    }
    CertPath certPath = cf.generateCertPath(mylist);

    // Validate chain
    PKIXParameters params = new PKIXParameters(keystore);
    params.setRevocationEnabled(false);

    CertPathValidator certPathValidator = CertPathValidator.getInstance(CertPathValidator
        .getDefaultType());
    CertPathValidatorResult result = certPathValidator.validate(certPath, params);

    PKIXCertPathValidatorResult pkixResult = (PKIXCertPathValidatorResult) result;
    TrustAnchor ta = pkixResult.getTrustAnchor();
    X509Certificate cert = ta.getTrustedCert();

    System.out.println("No exception, certificate validated");
  }
}
