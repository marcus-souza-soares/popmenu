# 🍽️ PopMenu Challenge - Restaurant Menu Management System

A comprehensive Ruby on Rails application that provides a RESTful API and web interface for managing restaurants, menus, and menu items with intelligent item reusability across menus.

[![Ruby](https://img.shields.io/badge/Ruby-3.3.0-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.2-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)](https://www.postgresql.org/)
[![RSpec](https://img.shields.io/badge/Tests-RSpec-green)](https://rspec.info/)

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Testing](#-testing)
- [Development](#-development)
- [Deployment](#-deployment)

## ✨ Features

### 🏢 Multi-Restaurant Management
- Full CRUD operations for restaurants
- Each restaurant can have multiple menus

### 📋 Smart Menu System
- Create multiple menus per restaurant (Breakfast, Lunch, Dinner, etc.)
- Nested resource structure for clean URL patterns
- Menu-specific item management

### 🍔 Intelligent Menu Item Reusability
**The Core Innovation:**
- **Globally Unique Items**: Menu items are unique by name across the entire system
- **Zero Duplication**: No duplicate menu items in the database
- **Multi-Menu Support**: The same item can appear on multiple menus
- **Automatic Reuse**: Adding an item with an existing name automatically reuses it
- **Flexible Pricing**: Prices can be updated when reusing items

**Example:**
```ruby
# Create "Caesar Salad" on the lunch menu
POST /restaurants/1/menus/1/menu_items
{ "menu_item": { "name": "Caesar Salad", "price_in_cents": 899 } }

# Add the same salad to dinner menu - automatically reuses the item!
POST /restaurants/1/menus/2/menu_items
{ "menu_item": { "name": "Caesar Salad" } }

# The item exists once in the database but appears on both menus!
```

### 🔒 Data Integrity
- Restaurant names are unique
- MenuItem names are globally unique
- Menu-MenuItem combinations are unique (no duplicates on same menu)
- Proper foreign key constraints and indexes
- Cascading deletes with smart cleanup

### 🧪 Comprehensive Testing
- RSpec test suite with 100+ tests
- API-focused testing approach
- Tests for nested resource scoping
- Security tests preventing cross-restaurant access
- Tests for item reusability and cascade behaviors

## 🏗️ Architecture

### Database Relationships

```
Restaurant (1) ──< (N) Menu (N) ──< (N) MenuItem
                            └──────────┘
                          MenuAssignment
                         (Join Table)
```

- **Restaurant** has many **Menus** (1:N)
- **Menu** belongs to **Restaurant** (N:1)
- **Menu** has many **MenuItems** through **MenuAssignments** (N:N)
- **MenuItem** has many **Menus** through **MenuAssignments** (N:N)

### Key Models

**Restaurant**
- Attributes: `name` (unique)
- Associations: `has_many :menus`

**Menu**
- Attributes: `name`, `restaurant_id`
- Associations: `belongs_to :restaurant`, `has_many :menu_items through :menu_assignments`

**MenuItem**
- Attributes: `name` (unique), `price_in_cents`
- Associations: `has_many :menus through :menu_assignments`
- Validations: Name uniqueness, price > 0

**MenuAssignment**
- Attributes: `menu_id`, `menu_item_id`
- The join table enabling many-to-many relationship
- Unique constraint on `[menu_id, menu_item_id]` combination

## 🚀 Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)

### Quick Setup

```bash
# Clone the repository
git clone git@github.com:marcus-souza-soares/popmenu.git
cd popmenu

# Run the automated setup script
./bin/setup_docker
```

The setup script will:
1. ✅ Build Docker images
2. ✅ Create and migrate the database
3. ✅ Seed with sample data (3 restaurants, 10 menus, 37 menu items)
4. ✅ Run RuboCop for code style checks
5. ✅ Run the test suite

### Manual Setup

If you prefer manual setup:

```bash
# Build Docker images
docker compose build

# Setup database
docker compose run --rm app bin/rails db:create
docker compose run --rm app bin/rails db:migrate
docker compose run --rm app bin/rails db:seed

# Start the application
docker compose up
```

### Accessing the Application

- **Web Interface**: http://localhost:3000
- **API Endpoint**: http://localhost:3000/restaurants.json

## 📡 API Documentation

### Base URL
```
http://localhost:3000
```

### Authentication
Currently, no authentication is required.

### Endpoints

#### Restaurants

```http
GET    /restaurants              # List all restaurants
POST   /restaurants              # Create a restaurant
GET    /restaurants/:id          # Show a restaurant
PUT    /restaurants/:id          # Update a restaurant
DELETE /restaurants/:id          # Delete a restaurant
```

**Example Request:**
```bash
# Get all restaurants
curl http://localhost:3000/restaurants.json

# Create a restaurant
curl -X POST http://localhost:3000/restaurants.json \
  -H "Content-Type: application/json" \
  -d '{"restaurant": {"name": "My Restaurant"}}'
```

**Example Response:**
```json
{
  "id": 1,
  "name": "Tasty Bites",
  "url": "http://localhost:3000/restaurants/1.json",
  "menus": [
    {
      "id": 1,
      "name": "Breakfast Menu",
      "url": "http://localhost:3000/restaurants/1/menus/1.json"
    }
  ],
  "created_at": "2024-10-21T12:00:00.000Z",
  "updated_at": "2024-10-21T12:00:00.000Z"
}
```

#### Menus

```http
GET    /restaurants/:restaurant_id/menus              # List menus
POST   /restaurants/:restaurant_id/menus              # Create a menu
GET    /restaurants/:restaurant_id/menus/:id          # Show a menu
PUT    /restaurants/:restaurant_id/menus/:id          # Update a menu
DELETE /restaurants/:restaurant_id/menus/:id          # Delete a menu
```

**Example Request:**
```bash
# Get all menus for a restaurant
curl http://localhost:3000/restaurants/1/menus.json

# Create a menu
curl -X POST http://localhost:3000/restaurants/1/menus.json \
  -H "Content-Type: application/json" \
  -d '{"menu": {"name": "Lunch Menu"}}'
```

**Example Response:**
```json
{
  "id": 1,
  "name": "Breakfast Menu",
  "url": "http://localhost:3000/restaurants/1/menus/1.json",
  "menu_items": [
    {
      "id": 1,
      "name": "Pancakes",
      "price_in_cents": 899,
      "url": "http://localhost:3000/restaurants/1/menus/1/menu_items/1.json"
    }
  ],
  "created_at": "2024-10-21T12:00:00.000Z",
  "updated_at": "2024-10-21T12:00:00.000Z"
}
```

#### Menu Items

```http
GET    /restaurants/:restaurant_id/menus/:menu_id/menu_items              # List menu items
POST   /restaurants/:restaurant_id/menus/:menu_id/menu_items              # Add item to menu
GET    /restaurants/:restaurant_id/menus/:menu_id/menu_items/:id          # Show a menu item
DELETE /restaurants/:restaurant_id/menus/:menu_id/menu_items/:id          # Remove from menu
```

**Example Request:**
```bash
# Add a new menu item
curl -X POST http://localhost:3000/restaurants/1/menus/1/menu_items.json \
  -H "Content-Type: application/json" \
  -d '{"menu_item": {"name": "Pancakes", "price_in_cents": 899}}'

# Remove item from menu (doesn't delete the item itself)
curl -X DELETE http://localhost:3000/restaurants/1/menus/1/menu_items/1.json
```

### HTTP Status Codes

- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST request
- `204 No Content` - Successful DELETE request
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors

### Error Response Format

```json
{
  "name": ["can't be blank"],
  "price_in_cents": ["must be greater than 0"]
}
```

## 🗄️ Database Schema

### Key Tables

**restaurants**
```sql
- id: bigint (PK)
- name: string (UNIQUE, NOT NULL)
- created_at: datetime
- updated_at: datetime
```

**menus**
```sql
- id: bigint (PK)
- name: string (NOT NULL)
- restaurant_id: bigint (FK, NOT NULL)
- created_at: datetime
- updated_at: datetime
```

**menu_items**
```sql
- id: bigint (PK)
- name: string (UNIQUE, NOT NULL)
- price_in_cents: integer (NOT NULL, > 0)
- created_at: datetime
- updated_at: datetime
```

**menu_assignments**
```sql
- id: bigint (PK)
- menu_id: bigint (FK, NOT NULL)
- menu_item_id: bigint (FK, NOT NULL)
- created_at: datetime
- updated_at: datetime
- UNIQUE INDEX on [menu_id, menu_item_id]
```

### Cascading Behavior

- Deleting a **Restaurant** → Deletes all its **Menus**
- Deleting a **Menu** → Deletes all **MenuAssignments** (but preserves **MenuItems**)
- Removing an item from a menu → Deletes the **MenuAssignment** only

## 🧪 Testing

### Running Tests

```bash
# Run all tests
docker compose run --rm app bin/rspec

# Run specific test file
docker compose run --rm app bin/rspec spec/controllers/restaurants_controller_spec.rb

# Run tests with documentation format
docker compose run --rm app bin/rspec --format documentation
```

### Test Coverage

- **Controllers**: Full API testing for all endpoints
- **Models**: Validation and association tests
- **Integration**: Nested resource scoping and security

### Sample Test Output

```
RestaurantsController
  GET #index
    ✓ returns a success response
    ✓ returns all restaurants
    ✓ includes menus in restaurant data

Finished in 2.34 seconds (files took 1.2 seconds to load)
120 examples, 0 failures
```

## 💻 Development

### Code Style

This project follows Ruby community style guidelines enforced by RuboCop:

```bash
# Check code style
docker compose run --rm app bin/rubocop

# Auto-fix issues
docker compose run --rm app bin/rubocop -a
```

### Sample Data

The seed file creates realistic test data:

- **3 Restaurants**: Tasty Bites, Ocean Grill & Bar, Bella Italia
- **10 Menus**: Various themed menus per restaurant
- **37 Unique Menu Items**: Diverse items demonstrating reusability
- **63 Menu Assignments**: Strategic item placements

## 📊 Project Stats

- **Ruby Version**: 3.3.0
- **Rails Version**: 8.0.2
- **Database**: PostgreSQL 17
- **Test Framework**: RSpec 8.0
- **Code Lines**: ~2,000+ lines
- **Test Coverage**: 120+ examples
- **API Endpoints**: 15+

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 👨‍💻 Author

**Marcus Souza Soares**
- GitHub: [@marcus-souza-soares](https://github.com/marcus-souza-soares)

## 🙏 Acknowledgments

- Built with Ruby on Rails
- Created as part of the PopMenu technical challenge

---
