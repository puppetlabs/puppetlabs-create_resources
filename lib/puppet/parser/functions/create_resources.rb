Puppet::Parser::Functions::newfunction(:create_resources, :doc => '
Converts a hash into a set of resources and adds them to the catalog.
Takes two parameters and an optional third paramter:
  create_resource($type, $resources, [$defaults])

This function assumes thatthe $resources hash is in the following form:
    {title => {parameters}, title2 => {parameters}, ... }

It will then create a resource of type $type for every element in the hash,
using the title and paramters for construction.

This is currently tested for defined resources, classes, as well as native types

If the third argument $defaults is passed, it has to be a hash as well and will be used as default values for all resources.
') do |args|
raise ArgumentError, ("create_resources(): wrong number of arguments (#{args.length}; must be <= 3)") if args.length < 2 || args.length > 3 

  # figure out what kind of resource we are
  type_of_resource = nil
  type_name = args[0].downcase
  if type_name == 'class'
    type_of_resource = :class
  else
    if resource = Puppet::Type.type(type_name.to_sym)
      type_of_resource = :type
    elsif resource = find_definition(type_name.downcase)
      type_of_resource = :define
    else 
      raise ArgumentError, "could not create resource of unknown type #{type_name}"
    end
  end
  # iterate through the resources to create
  defaults = args[2] || {}
  args[1].each do |title, params|
    raise ArgumentError, 'params should not contain title' if(params['title'])
    params = defaults.merge(params)
    case type_of_resource
    when :type
      res = resource.hash2resource(params.merge(:title => title))
      catalog.add_resource(res)
    when :define
      p_resource = Puppet::Parser::Resource.new(type_name, title, :scope => self, :source => resource)
      params.merge(:name => title).each do |k,v|
        p_resource.set_parameter(k,v)
      end
      resource.instantiate_resource(self, p_resource)
      compiler.add_resource(self, p_resource)
    when :class
      klass = find_hostclass(title)
      raise ArgumentError, "could not find hostclass #{title}" unless klass
      klass.ensure_in_catalog(self, params)
      compiler.catalog.add_class(title)
    end
  end
end
