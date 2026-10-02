alias Vetlink.{Accounts, Vets, Animals, Repo}

{:ok, owner} = Accounts.register(%{"name" => "Wanjiru Kamau", "email" => "owner@example.com", "password" => "password-1234", "phone" => "0712345678", "county" => "Kakamega"})
{:ok, vet} = Accounts.register(%{"name" => "Dr. Amina Wekesa", "email" => "vet@example.com", "password" => "password-1234", "role" => "vet", "county" => "Kakamega"})

profile = Vets.get_profile_by_user(vet.id)
{:ok, profile} = Vets.update_profile(profile, %{"clinic_name" => "Mobile practice", "specialty" => "Mixed and dairy practice", "species" => ["cattle", "goat", "sheep"], "services" => ["farm_visit", "online"], "home_visits" => true, "emergency" => true, "lat" => 0.2827, "lng" => 34.7519})
{:ok, _} = Vets.mark_verified(profile)

{:ok, max} = Animals.create_animal(owner, %{"name" => "Max", "species" => "dog", "breed" => "German Shepherd", "sex" => "male", "date_of_birth" => "2023-06-12"})
{:ok, _} = Animals.add_record(owner, max, :owner, %{"kind" => "note", "title" => "Max added to VetLink", "occurred_on" => "2026-10-01"})
IO.puts("Seeded. Log in as owner@example.com or vet@example.com (password-1234).")
