require "publishing_platform_api/content_store"
require "active_support/core_ext/hash/keys"

# This lives here and not in the Publishing Platform API adapters
# because no other application should be writing to the content store.
class ContentStoreWriter < PublishingPlatformApi::ContentStore
  def put_content_item(base_path:, content_item:)
    with_lock(base_path, :content_item) do
      put_json(content_item_url(base_path), content_item)
    end
  end

  def delete_content_item(base_path)
    with_lock(base_path, :content_item) do
      delete_json(content_item_url(base_path))
    end
  end

private

  def with_lock(*args, &block)
    # use endpoint to lock to a specific hostname
    lock_name = ([endpoint] + args).map(&:to_s).join("_")

    DistributedLock.lock(lock_name, &block)
  end
end
