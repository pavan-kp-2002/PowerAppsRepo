using DLaB.Xrm.Test;
using Microsoft.Xrm.Sdk;

namespace PluginAssemblyName.UnitTest.Builders
{
    public abstract class EntityBuilder<TEntity> : DLaB.Xrm.Test.Builders.DLaBEntityBuilder<TEntity, EntityBuilder<TEntity>> where TEntity : Entity, new()
    {       
        protected TEntity Record { get; set; }

        public EntityBuilder()
        {
            Record = new TEntity();
        }

        public EntityBuilder(Id id) : this()
        {
            Record.Id = id;
        }

        protected override TEntity BuildInternal()
        {
            return Record;
        }
    }
}
