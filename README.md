# CDC Real-time with Debezium Server

Complete Change Data Capture (CDC) solution streaming data changes from Oracle and PostgreSQL databases to Azure Event Hubs using Debezium Server.

## 🚀 Features

- ✅ **Real-time CDC** from Oracle (LogMiner) and PostgreSQL (logical replication)
- ✅ **Multiple Data Formats**: JSON, Avro, and CloudEvents
- ✅ **Azure Event Hubs Integration** for event streaming
- ✅ **Docker-based Deployment** with Docker Compose
- ✅ **Health Monitoring** endpoints
- ✅ **Automatic Offset Management** for reliable restarts
- ✅ **Sample Schemas and Data** for quick testing

## 📦 What's Inside

- **Oracle XE Database** with pre-configured CDC users and sample data
- **PostgreSQL 15** with logical replication enabled
- **Debezium Server 3.3.2** for both Oracle and PostgreSQL
- **Sample Data**: Customers, Orders, Products, and Inventory Transactions
- **Example Messages**: JSON, and CloudEvents format samples

## 🎯 Data Format Options

This project supports three data formats:

### 1. JSON (Default)
Standard Debezium JSON format with before/after states and metadata.
```json
{
  "before": {...},
  "after": {...},
  "source": {...},
  "op": "u",
  "ts_ms": 1765895667471
}
```

### 2. Avro
Binary format with schema evolution support.

### 3. CloudEvents
CNCF CloudEvents specification format with standard event attributes:
```json
{
  "id": "oracle;XEPDB1;DATAUSER.CUSTOMERS;3368006",
  "source": "oracle",
  "specversion": "1.0",
  "type": "io.debezium.connector.oracle.datachangeevent",
  "time": "2025-12-16T21:34:24.000Z",
  "datacontenttype": "application/json",
  "data": {
    "before": {...},
    "after": {...},
    "source": {...},
    "op": "u"
  }
}
```

CloudEvents provides a standardized way to describe events, making it easier to integrate with cloud-native platforms and event-driven architectures.

## 🏃 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/datacoolie/get_cdc_eventhub.git
   cd get_cdc_eventhub
   ```

2. **Create environment file**
   ```bash
   cp debezium-server/.env.example debezium-server/.env
   ```
   Edit `.env` to configure Azure Event Hubs credentials (optional for testing).

3. **Choose your data format** (in `.env`)
   ```properties
   # Options: json, avro, cloudevents
   DATA_FORMAT=json
   ```

4. **Start all services**
   ```bash
   docker-compose up -d
   ```

5. **Monitor startup**
   ```bash
   docker-compose logs -f
   ```

6. **Test CDC by making database changes**
   - See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed testing instructions

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup and configuration guide
- **[CRUD_SIMULATION_README.md](CRUD_SIMULATION_README.md)** - Scripts for testing CDC with CRUD operations

## 🔧 Configuration Files

- `docker-compose.yml` - Container orchestration
- `debezium-server/oracle-application.properties` - Oracle CDC configuration
- `debezium-server/postgres-application.properties` - PostgreSQL CDC configuration
- `debezium-server/.env` - Environment variables for Azure and format settings
- `oracle-init.sql` - Oracle schema and sample data
- `postgres-init.sql` - PostgreSQL schema and sample data

## 📋 Example Messages

- `oracle-message.json` - Standard Debezium JSON format from Oracle
- `postgres-message.json` - Standard Debezium JSON format from PostgreSQL
- `oracle-cloudevents-message.json` - CloudEvents format from Oracle
- `postgres-cloudevents-message.json` - CloudEvents format from PostgreSQL

## 🌐 CloudEvents Support

CloudEvents is a CNCF specification for describing event data in common formats. This project supports CloudEvents format for both Oracle and PostgreSQL connectors.

**Benefits of CloudEvents:**
- **Standardization**: Consistent event structure across different sources
- **Interoperability**: Easy integration with cloud platforms and serverless functions
- **Metadata**: Rich event context with standard attributes (id, source, type, time)
- **Portability**: Platform-agnostic event format

**Configuration:**
Set `DATA_FORMAT=cloudevents` in your `.env` file to enable CloudEvents format.

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed CloudEvents configuration options.

## 🔗 Architecture

```
┌─────────────┐      ┌──────────────────┐      ┌────────────────────┐
│   Oracle    │─────▶│ Debezium Server  │─────▶│ Azure Event Hubs   │
│     XE      │      │    (Oracle)      │      │                    │
└─────────────┘      └──────────────────┘      │  ┌──────────────┐  │
                                                │  │ Oracle Topic │  │
┌─────────────┐      ┌──────────────────┐      │  └──────────────┘  │
│ PostgreSQL  │─────▶│ Debezium Server  │─────▶│                    │
│     15      │      │  (PostgreSQL)    │      │  ┌──────────────┐  │
└─────────────┘      └──────────────────┘      │  │ PG Topic     │  │
                                                │  └──────────────┘  │
                                                └────────────────────┘
```

## 🛠️ Requirements

- Docker Desktop (8GB+ RAM)
- Docker Compose
- Azure Event Hubs namespace (optional, for production)

## 📖 Additional Resources

- [Debezium Documentation](https://debezium.io/documentation/)
- [CloudEvents Specification](https://cloudevents.io/)
- [Azure Event Hubs Documentation](https://docs.microsoft.com/en-us/azure/event-hubs/)

## 📝 License

This project is open source and available for educational and commercial use.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

**Last Updated**: December 2025  
**Debezium Version**: 3.3.2.Final  
**Supported Formats**: JSON, Avro, CloudEvents
