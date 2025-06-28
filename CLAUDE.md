# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Starting the Application
- `bin/dev` - Start the development server (Rails server only)
- `bin/rails server` - Start Rails server directly
- `bin/rails console` - Open Rails console
- `bin/rails console --sandbox` - Open Rails console in sandbox mode

### CSS and Asset Pipeline
- `bin/rails tailwindcss:watch` - Watch and compile Tailwind CSS changes
- `bin/rails assets:precompile` - Precompile assets for production

### Database Operations
- `bin/rails db:create` - Create the database
- `bin/rails db:migrate` - Run pending migrations
- `bin/rails db:seed` - Seed the database
- `bin/rails db:reset` - Drop, create, migrate, and seed the database

### Testing
- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/models/` - Run model tests only
- `bundle exec rspec spec/components/` - Run component tests only

### Code Quality and Linting
- `bundle exec rubocop` - Run RuboCop linter
- `bundle exec rubocop -a` - Run RuboCop with auto-fix
- `bundle exec brakeman` - Run security analysis

### Background Jobs
- `bin/jobs` - Start Solid Queue job processor

## Architecture Overview

This is a Ruby on Rails 8.0 service marketplace application called "Near You" that connects service providers with users.

### Core Models and Relationships
- **User**: Authentication via Devise, can be either a customer or have an associated Provider
- **Provider**: Service providers with categories like health/wellness, beauty, home services, etc.
- **Appointment**: Bookings between users and providers with time slots and Stripe payment integration
- **Availability**: Provider's available time slots and session durations
- **Review/ReviewResponse**: Rating and feedback system between users and providers

### Key Integrations
- **Stripe**: Payment processing and Connect accounts for providers
- **Devise**: User authentication and registration
- **Noticed**: Notification system for appointments and reviews
- **Avo**: Admin panel for managing resources
- **ViewComponent**: Component-based view architecture
- **Solid Queue**: Background job processing
- **Active Storage**: File uploads for provider images

### Frontend Architecture
- **Tailwind CSS**: Utility-first CSS framework
- **Stimulus**: JavaScript framework for interactive behaviors
- **Turbo**: SPA-like page acceleration
- **ViewComponents**: Reusable UI components (NavbarComponent, FooterComponent)

### Service Categories
The Provider model defines extensive service categories including:
- Health & Wellness (masseur, personal trainer, nutritionist, etc.)
- Beauty & Grooming (hairstylist, makeup artist, nail technician, etc.)
- Home Services (electrician, plumber, gardener, etc.)
- Education (tutor, music teacher, language coach, etc.)
- Creative Services (photographer, videographer, etc.)
- Event Services (DJ, caterer, entertainer)
- Specialty & Miscellaneous (astrologer, translator, pet groomer, etc.)

### Database
- **PostgreSQL**: Primary database
- **Solid Cache**: SQLite-based caching
- **Solid Cable**: SQLite-based Action Cable adapter
- **Solid Queue**: SQLite-based job queue

### Deployment
- **Kamal**: Docker-based deployment system
- Multiple environments: development, staging, production
- Health checks via `/up` endpoint

### Key Business Logic
- **Appointment Scheduling**: Time slot validation with overlap prevention
- **Payment Flow**: Stripe checkout integration with provider payouts
- **Rating System**: Automatic average rating calculation for providers
- **Notification System**: Email notifications for appointment confirmations/reminders
- **Admin Access**: Avo admin panel restricted to admin users

### Testing Framework
- **RSpec**: Primary testing framework
- **FactoryBot**: Test data generation
- **Faker**: Fake data for testing
- **Shoulda Matchers**: Additional RSpec matchers
- **Capybara + Selenium**: System/integration testing