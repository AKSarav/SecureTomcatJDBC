/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.sql.SQLException;
import java.util.Properties;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.naming.Context;
import javax.sql.DataSource;

import org.apache.juli.logging.Log;
import org.apache.juli.logging.LogFactory;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.apache.tomcat.jdbc.pool.DataSourceFactory;
import org.apache.tomcat.jdbc.pool.PoolConfiguration;
import org.apache.tomcat.jdbc.pool.XADataSource;

public class SecureTomcatDataSourceImpl extends DataSourceFactory {

    private static final Log log = LogFactory.getLog(SecureTomcatDataSourceImpl.class);

    private EncDecJDBCPass encryptor = null;

    public SecureTomcatDataSourceImpl() {
        try {
            encryptor = new EncDecJDBCPass(); // If you've used your own secret key, pass it in...
        } catch (InvalidKeyException | NoSuchAlgorithmException | NoSuchPaddingException | UnsupportedEncodingException e) {
            log.fatal("Error instantiating decryption class.", e);
            throw new RuntimeException(e);
        }
    }

    @Override
    public DataSource createDataSource(Properties properties, Context context, boolean XA) throws InvalidKeyException,
            IllegalBlockSizeException, BadPaddingException, SQLException, NoSuchAlgorithmException,
            NoSuchPaddingException {
        // Here we decrypt our password.
        PoolConfiguration poolProperties = SecureTomcatDataSourceImpl.parsePoolProperties(properties);
        poolProperties.setPassword(encryptor.decrypt(poolProperties.getPassword()));

        // The rest of the code is copied from Tomcat's DataSourceFactory.
        if (poolProperties.getDataSourceJNDI() != null && poolProperties.getDataSource() == null) {
            performJNDILookup(context, poolProperties);
        }
        org.apache.tomcat.jdbc.pool.DataSource dataSource = XA ? new XADataSource(poolProperties)
                : new org.apache.tomcat.jdbc.pool.DataSource(poolProperties);
        
        String Name = SecureTomcatDataSourceImpl.getProperties("name").toString();
        String URL = poolProperties.getUrl();
        String username = poolProperties.getUsername();
        Logger.getLogger(SecureTomcatDataSourceImpl.class.getName()).log(Level.INFO, "Creating a New Connection Pool for DataSource "+Name+" with URL "+URL+" and the  username "+username);
        
        dataSource.createPool();

        return dataSource;
    }

}
