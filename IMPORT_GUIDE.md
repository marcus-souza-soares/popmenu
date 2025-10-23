# Restaurant Data Import Guide

## Overview

This guide explains how to import restaurant data from JSON files into the PopMenu system using the HTTP import endpoint. The import system uses a sophisticated adapter pattern with Interactor services to parse, validate, and persist restaurant, menu, and menu item data.

## Features

- ✅ **HTTP Endpoint** - Accept JSON files via POST request
- ✅ **Flexible JSON Format** - Handles both `menu_items` and `dishes` keys
- ✅ **Adapter Pattern** - Normalizes inconsistent data structures
- ✅ **Service Objects** - Uses Interactor gem for clean, testable services
- ✅ **Comprehensive Logging** - Detailed logs for every operation
- ✅ **Exception Handling** - Graceful error handling with detailed feedback
- ✅ **Smart Item Reuse** - Menu items are globally unique and reused across menus
- ✅ **Detailed Results** - Success/fail status for each restaurant, menu, and item

## JSON Format

The import system accepts restaurant data in JSON format:

```json
{
  "restaurants": [
    {
      "name": "Poppo's Cafe",
      "menus": [
        {
          "name": "lunch",
          "menu_items": [
            {
              "name": "Burger",
              "price": 9.00
            },
            {
              "name": "Small Salad",
              "price": 5.00
            }
          ]
        }
      ]
    }
  ]
}
```

### Format Flexibility

The system handles variations in the JSON structure:

1. **Menu Items Key**: Both `menu_items` and `dishes` keys are supported
2. **Price Format**: Accepts decimal numbers (converted to cents internally)
3. **Special Characters**: Supports quotes, apostrophes, and other special characters
4. **Duplicate Items**: Automatically reuses items with the same name across menus

### Example with Variations

```json
{
  "restaurants": [
    {
      "name": "Casa del Poppo",
      "menus": [
        {
          "name": "lunch",
          "dishes": [
            {
              "name": "Mega \"Burger\"",
              "price": 22.00
            }
          ]
        }
      ]
    }
  ]
}
```

## Import Methods

### Method 1: Using cURL with File Upload

The most common method is to upload a JSON file:

```bash
curl -X POST http://localhost:3000/imports/restaurants \
  -F "file=@restaurant_data.json"
```

### Method 2: Using cURL with JSON Body

You can also send raw JSON in the request body:

```bash
curl -X POST http://localhost:3000/imports/restaurants \
  -H "Content-Type: application/json" \
  -d @restaurant_data.json
```

### Method 3: Using HTTPie

If you have HTTPie installed:

```bash
http POST http://localhost:3000/imports/restaurants < restaurant_data.json
```

### Method 4: Using Postman

1. Open Postman
2. Create a new POST request to `http://localhost:3000/imports/restaurants`
3. In the Body tab, select `form-data`
4. Add a key named `file` with type `File`
5. Choose your JSON file
6. Click Send

### Method 5: Rails Console (for testing)

```ruby
# From Rails console
json_content = File.read("restaurant_data.json")
result = ImportRestaurantsFromJson.call(json_content: json_content)

puts "Success: #{result.success?}"
puts "Message: #{result.message}"
puts "Restaurants: #{result.total_restaurants}"
puts "Menus: #{result.total_menus}"
puts "Menu Items: #{result.total_menu_items}"

# View detailed logs
result.logs.each do |log|
  puts "[#{log[:level]}] #{log[:message]}"
end
```

## Response Format

### Success Response

When the import succeeds, you'll receive a 201 Created response:

```json
{
  "success": true,
  "message": "Import completed successfully",
  "summary": {
    "restaurants": 2,
    "menus": 3,
    "menu_items": 4,
    "assignments": 5
  },
  "results": [
    {
      "restaurant_name": "Poppo's Cafe",
      "restaurant_id": 1,
      "status": "success",
      "menus": [
        {
          "menu_name": "lunch",
          "menu_id": 1,
          "status": "success",
          "menu_items": [
            {
              "item_name": "Burger",
              "menu_item_id": 1,
              "price_in_cents": 900,
              "status": "success",
              "action": "created",
              "assignment_id": 1,
              "assignment_action": "created"
            }
          ]
        }
      ]
    }
  ],
  "logs": [
    {
      "level": "info",
      "message": "Successfully parsed JSON data"
    },
    {
      "level": "info",
      "message": "Successfully adapted 2 restaurant(s)"
    },
    {
      "level": "info",
      "message": "Menu item 'Burger' created and assigned to menu 'lunch'"
    }
  ]
}
```

### Error Response

When the import fails, you'll receive a 422 Unprocessable Entity response:

```json
{
  "success": false,
  "message": "Validation failed with 2 error(s)",
  "validation_errors": [
    {
      "path": "restaurants[0]",
      "message": "name is required",
      "severity": "error"
    }
  ],
  "adapter_errors": [],
  "logs": [
    {
      "level": "error",
      "message": "restaurants[0]: name is required"
    }
  ]
}
```

## Import Behavior

### Restaurant Management

- **New Restaurant**: Creates a new restaurant record
- **Existing Restaurant**: Reuses the existing restaurant and adds menus to it
- **Validation**: Restaurant name is required and must be unique

### Menu Management

- **New Menu**: Creates a new menu for the restaurant
- **Existing Menu**: Reuses the existing menu if same name exists for that restaurant
- **Validation**: Menu name is required

### Menu Item Management

- **New Item**: Creates a new menu item (globally unique by name)
- **Existing Item**: Reuses the item and updates the price if different
- **Multiple Menus**: The same item can appear on multiple menus
- **Validation**: Item name is required, price must be greater than 0

### Example Workflow

1. Import restaurant "Poppo's Cafe" with a "Burger" at $9.00
   - Creates: Restaurant, Menu, MenuItem, MenuAssignment
   
2. Import same restaurant with a "dinner" menu including "Burger" at $15.00
   - Reuses: Restaurant, MenuItem "Burger"
   - Creates: New Menu "dinner", New MenuAssignment
   - Updates: MenuItem "Burger" price to $15.00

## Running the Sample Import

A sample file `restaurant_data.json` is included in the project root:

```bash
# Make sure the application is running
docker compose up

# In another terminal, run the import
curl -X POST http://localhost:3000/imports/restaurants \
  -F "file=@restaurant_data.json" | jq
```

The `| jq` part formats the JSON response (requires jq to be installed).

## Architecture

### Components

1. **RestaurantJsonAdapter** (`app/adapters/restaurant_json_adapter.rb`)
   - Normalizes JSON data structure
   - Handles `menu_items` vs `dishes` variations
   - Converts prices to cents

2. **ParseJsonData** (`app/interactors/parse_json_data.rb`)
   - Parses raw JSON string
   - Uses adapter to normalize data
   - Handles JSON parsing errors

3. **ValidateRestaurantData** (`app/interactors/validate_restaurant_data.rb`)
   - Validates data structure
   - Checks required fields
   - Collects validation errors

4. **ImportRestaurantData** (`app/interactors/import_restaurant_data.rb`)
   - Creates/updates database records
   - Handles transactions
   - Manages item reuse logic

5. **ImportRestaurantsFromJson** (`app/interactors/import_restaurants_from_json.rb`)
   - Organizer that coordinates all interactors
   - Provides unified interface
   - Collects logs from all steps

6. **ImportsController** (`app/controllers/imports_controller.rb`)
   - HTTP endpoint handler
   - Extracts JSON from various sources
   - Formats responses

### Data Flow

```
JSON File Upload
      ↓
ImportsController
      ↓
ImportRestaurantsFromJson (Organizer)
      ↓
   ┌──────────────────────────────┐
   │                              │
   ↓                              │
ParseJsonData                     │
   │                              │
   ├→ RestaurantJsonAdapter       │
   │                              │
   ↓                              │
ValidateRestaurantData            │
   │                              │
   ↓                              │
ImportRestaurantData              │
   │                              │
   └──────────────────────────────┘
      ↓
JSON Response with Results & Logs
```

## Testing

The import system has comprehensive test coverage:

```bash
# Run all import-related tests
docker compose run --rm app bundle exec rspec spec/adapters spec/interactors spec/controllers/imports_controller_spec.rb

# Run specific test files
docker compose run --rm app bundle exec rspec spec/adapters/restaurant_json_adapter_spec.rb
docker compose run --rm app bundle exec rspec spec/interactors/import_restaurants_from_json_spec.rb
docker compose run --rm app bundle exec rspec spec/controllers/imports_controller_spec.rb
```

### Test Coverage

- ✅ Adapter: 60+ test cases
- ✅ Interactors: 70+ test cases
- ✅ Controller: 17+ test cases
- ✅ Integration: Full end-to-end scenarios

## Troubleshooting

### Common Issues

#### 1. "No JSON content provided"

**Cause**: The request doesn't contain JSON data or file.

**Solution**: Ensure you're including the file in the request:
```bash
curl -X POST http://localhost:3000/imports/restaurants -F "file=@restaurant_data.json"
```

#### 2. "Invalid JSON format"

**Cause**: The JSON is malformed.

**Solution**: Validate your JSON using a tool like https://jsonlint.com/

#### 3. "Validation failed"

**Cause**: Required fields are missing or invalid.

**Solution**: Check the `validation_errors` array in the response for specific issues.

#### 4. Database connection errors

**Cause**: PostgreSQL is not running.

**Solution**: Ensure the database container is running:
```bash
docker compose up db
```

### Viewing Logs

Check the Rails logs for detailed information:

```bash
docker compose logs app

# Or tail the logs
docker compose logs -f app
```

## Advanced Usage

### Batch Import Script

Create a Ruby script for batch importing:

```ruby
# batch_import.rb
require 'net/http'
require 'json'

def import_file(filepath)
  uri = URI('http://localhost:3000/imports/restaurants')
  request = Net::HTTP::Post.new(uri)
  request.set_form([['file', File.open(filepath)]], 'multipart/form-data')
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  result = JSON.parse(response.body)
  puts "Import #{result['success'] ? 'succeeded' : 'failed'} for #{filepath}"
  puts "Summary: #{result['summary']}" if result['success']
  
  result
end

# Import multiple files
Dir.glob('data/*.json').each do |file|
  import_file(file)
end
```

### Dry Run (Validation Only)

To validate without importing, use the interactors directly:

```ruby
json_content = File.read("restaurant_data.json")

# Parse and validate only
result = ParseJsonData.call(json_content: json_content)
if result.success?
  result = ValidateRestaurantData.call(adapted_data: result.adapted_data)
  puts result.success? ? "Validation passed!" : "Validation failed: #{result.validation_errors}"
end
```

## API Endpoint Reference

### POST /imports/restaurants

Import restaurant data from JSON file or body.

**Request:**
- Content-Type: `multipart/form-data` or `application/json`
- Body: JSON file or raw JSON content

**Response Codes:**
- `201 Created` - Import successful
- `422 Unprocessable Entity` - Validation or parsing error
- `500 Internal Server Error` - Unexpected error

**Response Fields:**
- `success` (boolean) - Overall success status
- `message` (string) - Summary message
- `summary` (object) - Counts of created/updated records
- `results` (array) - Detailed results for each restaurant
- `logs` (array) - All log messages from the import process
- `validation_errors` (array) - Validation errors if any
- `adapter_errors` (array) - Adapter errors if any

## Related Documentation

- [README.md](README.md) - Main project documentation
- [API Documentation](http://localhost:3000/api-docs/) - Swagger UI (when running)
- Database Schema - See [README.md](README.md#database-schema)

## Support

For issues or questions:
1. Check the logs: `docker compose logs app`
2. Review test cases for examples: `spec/interactors/import_restaurants_from_json_spec.rb`
3. Open an issue on the project repository

---

**Last Updated**: October 23, 2025
**Version**: 1.0.0

