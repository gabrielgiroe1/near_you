# frozen_string_literal: true

class CategoryCardsComponent < ViewComponent::Base
  CATEGORIES = [
    { name: "Coafor și hairstyling", image: "categories/coafor.jpg", filters: { service_type: "Hairstylist" } },
    { name: "Frizerie și barber shop", image: "categories/frizerie.jpg", filters: { service_type: "Barber" } },
    { name: "Unghii cu gel - Nails", image: "categories/unghii.jpg", filters: { service_type: "Nail Technician" } },
    { name: "Cosmetică", image: "categories/cosmetica.jpg", filters: { service_type: "Facial Expert" } },
    { name: "Extensii gene - Lashes", image: "categories/extensii_gene.jpg", filters: { service_type: "Eyelash Technician" } },
    { name: "Epilare definitivă", image: "categories/epilare.jpg", filters: { service_type: "Tanning Specialist" } },
    { name: "Tratamente și remodelare corporală", image: "categories/tratamente.jpg", filters: { category: "Health & Wellness" } },
    { name: "Estetică medicală și injectabile", image: "categories/estetica.jpg", filters: { category: "Beauty & Grooming" } },
    { name: "Masaj", image: "categories/masaj.jpg", filters: { service_type: "Masseur" } },
    { name: "Micropigmentare", image: "categories/micropigmentare.jpg", filters: { service_type: "Makeup Artist" } },
    { name: "Makeup", image: "categories/makeup.jpg", filters: { service_type: "Makeup Artist" } },
    { name: "Alte servicii", image: "categories/alte_servicii.jpg", filters: {} }
  ].freeze
end
