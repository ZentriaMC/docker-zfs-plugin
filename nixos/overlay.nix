self: super:
{
  docker-zfs-plugin = super.callPackage ./.. { };
}
